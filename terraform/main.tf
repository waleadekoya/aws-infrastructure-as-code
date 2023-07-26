provider "aws" {
  region = "us-west-2"
}


module "security_group" {
  source = "./modules/aws/security_group"
  // other configuration...
}

module "ec2-linux" {
  source                 = "./modules/aws/ec2"
  instance_type          = var.environment == "prod" ? "t2.large" : "t2.micro" #"t2.micro"
  vpc_security_group_ids = [module.security_group.sg_id]
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

module "vpc" {
  source       = "./modules/aws/vpc"
  cidr_block   = "10.0.0.0/16"
  vpc_name     = "${var.environment}-custom-vpc"
  environment  = var.environment
}


terraform {
  backend "s3" {
    bucket = "terraform-state-backend-store"
    key    = "states/current"
    region = "eu-west-1"
  }
}
