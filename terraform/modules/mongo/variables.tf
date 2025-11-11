variable "vpc_id" {}
variable "subnet_id" {}
variable "project_name" {}
variable "mongo_instance_type" { type = string }
variable "mongo_key_name" { type = string }
variable "allowed_security_group_ids" { type = list(string) } # who can access Mongo (security groups)
