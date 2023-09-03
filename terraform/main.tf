provider "aws" {
  region = "eu-west-1"
}

# In Terraform, modules receive inputs via variables.
module "vpc" {
  source       = "./modules/aws/vpc"
  cidr_block   = "10.0.0.0/16"
  vpc_name     = "custom-vpc"
  environment  = var.environment
  gateway_name = "internet_gateway"
  route_table_name = "route_table"
  subnet_cidr_block = "10.0.1.0/24"
  public_subnet_cidr_block = "10.0.2.0/24"
  subnet_name = "subnet"
}

# In Terraform, modules receive inputs via variables.
module "security_group" {
  source = "./modules/aws/security_group"
  vpc_id  = module.vpc.id  # Pass the VPC ID here (must be defined in outputs.tf file of the VPC module)
  // other configuration...
}

module "ec2-linux" {
  source                 = "./modules/aws/ec2"
  instance_type          = var.environment == "prod" ? "t2.large" : "t2.micro" #"t2.micro"
  vpc_security_group_ids = [module.security_group.sg_id]
  subnet_id = module.vpc.public_subnet_id # must be referenced in the outputs.tf of the vpc module
  user_data_file         = "default.sh"
  tags                   = {
    Name = "ec2-sandbox-${var.environment}"
  }

}

data "aws_caller_identity" "current" {}

module "s3_bucket" {
  source = "./modules/aws/s3"

  bucket = "s3-bucket-${data.aws_caller_identity.current.account_id}"
  acl    = "private"

  tags = {
    Environment = "dev"
    Name        = "My bucket"
  }
}

module "iam" {
  source = "./modules/aws/iam"

  role_name    = "terraform-execution-role-${var.environment}"
  service_name = "ec2.amazonaws.com"
  policy_name  = "infra_deployment_policy"
  actions      = ["s3:*"]
  resources    = ["*"]
}


terraform {
  backend "s3" {
    bucket = "terraform-state-backend-store"
    key    = "states/current"
    region = "eu-west-1"
  }
}

#module "vpc-public-registry" {
#  # https://developer.hashicorp.com/terraform/language/modules/sources
#  source = "terraform-aws-modules/vpc/aws"
#
#  name = "my-vpc"
#  cidr = "10.0.0.0/16"
#
#  azs             = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
#  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
#  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
#
#  enable_nat_gateway = true
#  enable_vpn_gateway = true
#
#  tags = {
#    Terraform = "true"
#    Environment = "dev"
#  }
#}
