variable "vpc_id" {}
variable "public_subnets" { type = list(string) }
variable "private_subnets" { type = list(string) }
variable "project_name" {}
variable "ecr_repo_url" {}
variable "asg_desired" { type = number }
variable "asg_min" { type = number }
variable "asg_max" { type = number }
variable "instance_type" { type = string }
variable "mongo_private_ip" { type = string }
