# Security group for MongoDB
resource "aws_security_group" "mongo_sg" {
  name = "${var.project_name}-mongo-sg"
  vpc_id = var.vpc_id
  description = "Allow mongo from ECS instances (set later) and admin"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # for SSH - restrict in production
  }
  ingress {
    from_port = 27017
    to_port = 27017
    protocol = "tcp"
    # will be overridden by module consumer who can pass allowed_security_group_ids
    cidr_blocks = []
    security_groups = var.allowed_security_group_ids
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.project_name}-mongo-sg" }
}

resource "aws_instance" "mongo" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.mongo_instance_type
  subnet_id     = var.subnet_id
  key_name      = var.mongo_key_name != "" ? var.mongo_key_name : null
  security_groups = [aws_security_group.mongo_sg.id]
  user_data = <<-EOF
              #!/bin/bash
              set -x
              apt-get update -y
              apt-get install -y mongodb
              systemctl enable mongodb
              systemctl start mongodb
              # bind to 0.0.0.0
              sed -i 's/bind_ip = 127.0.0.1/bind_ip = 0.0.0.0/' /etc/mongodb.conf || true
              systemctl restart mongodb || true
              EOF

  tags = { Name = "${var.project_name}-mongo" }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}
