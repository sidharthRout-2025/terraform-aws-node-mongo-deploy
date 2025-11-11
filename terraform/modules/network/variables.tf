variable "vpc_cidr" {}
variable "public_subnets" { type = list(string) }
variable "private_subnets" { type = list(string) }
variable "project_name" { type = string }

data "aws_availability_zones" "available" {}