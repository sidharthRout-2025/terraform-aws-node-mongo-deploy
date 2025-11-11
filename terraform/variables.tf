variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "devops-tech-test"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24","10.0.2.0/24"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.0.10.0/24","10.0.11.0/24"]
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "asg_desired" { type = number; default = 2 }
variable "asg_min" { type = number; default = 1 }
variable "asg_max" { type = number; default = 3 }

variable "docker_image_tag" { type = string; default = "latest" }
variable "ecr_repo_name" { type = string; default = "devops-tech-test-app" }

# terraform backend params
variable "tfstate_bucket" { type = string; default = "my-terraform-state-bucket-unique" }
variable "tfstate_key" { type = string; default = "devops-tech-test/terraform.tfstate" }
variable "tfstate_lock_table" { type = string; default = "tfstate-lock-table-unique" }

# DB instance details for Mongo EC2
variable "mongo_instance_type" { type = string; default = "t3.medium" }
variable "mongo_key_name" { type = string; default = "" }