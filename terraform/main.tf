locals {
  name = var.project_name
}

module "network" {
  source = "./modules/network"
  vpc_cidr = var.vpc_cidr
  public_subnets = var.public_subnets
  private_subnets = var.private_subnets
  project_name = local.name
}

module "ecr" {
  source = "./modules/ecr"
  name   = var.ecr_repo_name
}

module "alb" {
  source = "./modules/alb"
  vpc_id = module.network.vpc_id
  public_subnets = module.network.public_subnets
  project_name = local.name
}

module "mongo" {
  source = "./modules/mongo"
  vpc_id = module.network.vpc_id
  subnet_id = module.network.private_subnets[0]
  project_name = local.name
  mongo_instance_type = var.mongo_instance_type
  mongo_key_name = var.mongo_key_name
  allowed_security_group_ids = [module.alb.alb_sg_id] # only ALB (if app calls DB) and ecs will be allowed too below
}

module "ecs_ec2" {
  source = "./modules/ecs_ec2"
  vpc_id = module.network.vpc_id
  public_subnets = module.network.public_subnets
  private_subnets = module.network.private_subnets
  ecr_repo_url = module.ecr.ecr_repository_url
  project_name = local.name

  asg_desired = var.asg_desired
  asg_min = var.asg_min
  asg_max = var.asg_max
  instance_type = var.instance_type

  mongo_private_ip = module.mongo.mongo_private_ip
}
