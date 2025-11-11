output "cluster_name" { value = aws_ecs_cluster.this.name }
output "service_name" { value = aws_ecs_service.service.name }
output "ecs_instance_sg_id" { value = aws_security_group.ecs_instances_sg.id }
