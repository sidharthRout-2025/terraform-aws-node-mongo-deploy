data "aws_ami" "amazon_linux" {
  most_recent = true
  owners = ["137112412989"] # Amazon
  filter {
    name = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

resource "aws_security_group" "ecs_instances_sg" {
  name   = "${var.project_name}-ecs-sg"
  vpc_id = var.vpc_id
  description = "ECS instances security group"
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["10.0.0.0/8"] # allow internal traffic (simplified)
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-ecs-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# Launch template to run ECS agent and join cluster
resource "aws_launch_template" "ecs_lt" {
  name_prefix = "${var.project_name}-ecs-"
  image_id = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }
  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.ecs_instances_sg.id]
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.this.name} > /etc/ecs/ecs.config
    # install updates & docker if not present (Amazon ECS optimized AMI has docker & ecs agent)
    EOF)
}

resource "aws_autoscaling_group" "ecs_asg" {
  desired_capacity     = var.asg_desired
  max_size             = var.asg_max
  min_size             = var.asg_min
  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        id = aws_launch_template.ecs_lt.id
        version = "$Latest"
      }
    }
  }
  vpc_zone_identifier = var.public_subnets
  tags = [
    {
      key                 = "Name"
      value               = "${var.project_name}-ecs-instance"
      propagate_at_launch = true
    }
  ]
  lifecycle {
    create_before_destroy = true
  }
}

# Task definition (bridge to ECR repo)
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-task"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name = "app"
      image = "${var.ecr_repo_url}:${var.image_tag}"
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort = 3000
        }
      ]
      environment = [
        { name = "MONGO_URI", value = "mongodb://${var.mongo_private_ip}:27017/devops_test" },
        { name = "PORT", value = "3000" },
        { name = "ENV", value = "prod" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group = "/ecs/${var.project_name}"
          awslogs-region = var.aws_region
          awslogs-stream-prefix = "app"
        }
      }
    }
  ])
}

# CloudWatch log group
resource "aws_cloudwatch_log_group" "ecs" {
  name = "/ecs/${var.project_name}"
  retention_in_days = 14
}

# ECS Service attached to ALB target group via root module's alb target group
resource "aws_ecs_service" "service" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
  launch_type     = "EC2"

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent = 200

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = "app"
    container_port   = 3000
  }

  depends_on = [aws_autoscaling_group.ecs_asg]
}
