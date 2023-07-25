provider "aws" {
  region = "us-west-2"
}


/*
aws ec2 describe-images \
    --region <region> \
    --owners 099720109477 \
    --filters 'Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*' 'Name=virtualization-type,Values=hvm' \
    --query 'Images[*].[ImageId,CreationDate]' \
    --output text \
    | sort -k2 -r \
    | head -n1

*/
data "aws_ami" "latest_ubuntu_ami" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "latest_amz_linux_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

#module "security_group" {
#  source = "../security_group"
#  // other configuration...
#}



resource "aws_instance" "example" {
  ami           = data.aws_ami.latest_ubuntu_ami.id
  instance_type = var.instance_type
  user_data = file(var.user_data_file)
  vpc_security_group_ids = var.vpc_security_group_ids
  tags = var.tags
}
