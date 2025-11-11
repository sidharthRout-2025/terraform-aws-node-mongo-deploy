output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "ecs_cluster_name" {
  value = module.ecs_ec2.cluster_name
}

output "ecs_service_name" {
  value = module.ecs_ec2.service_name
}
