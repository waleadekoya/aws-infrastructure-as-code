provider "aws" {
  region = "eu-west-2"
}

# Generate a new SSH key pair
resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create a new AWS key pair using the public key
resource "aws_key_pair" "generated_key_pair" {
  key_name   = "my_key_pair"
  public_key = tls_private_key.example_ssh.public_key_openssh
}

# Output the private key
output "private_key_pem" {
  value     = tls_private_key.example_ssh.private_key_pem
  sensitive = true
}

# Output the key pair name
output "key_pair_name" {
  value = aws_key_pair.generated_key_pair.key_name
}

data "aws_vpc" "default" {
  default = true
}

# Fetch all subnet IDs
data "aws_subnets" "all" {
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets#attributes-reference
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  #  tags = {
  #    Private = true
  #  }
}

data "aws_subnet" "example" {
  for_each = toset(data.aws_subnets.all.ids)
  id       = each.value
}

# Create a local variable to hold the list of subnet IDs
locals {
  subnet_ids = [for s in data.aws_subnet.example : s.id]
}

data "aws_availability_zones" "available" {}

# Create an Elastic IP
resource "aws_eip" "nat_eip" {}

# Create NAT Gateway - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway
# https://docs.aws.amazon.com/vpc/latest/userguide/nat-gateway-troubleshooting.html
# https://docs.aws.amazon.com/vpc/latest/userguide/nat-gateway-troubleshooting.html#nat-gateway-troubleshooting-no-internet-connection
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id # NAT GW must be created in a public subnet
  #subnet_id     = local.subnet_ids[0]  # Use the first subnet ID
  connectivity_type = "public"
  tags = {
    Name = "${var.environment}-nat-gateway"
  }
}

resource "aws_security_group" "private_sg" {
  name        = "${var.environment}-private-sg"
  description = "Private security group"
  vpc_id      = data.aws_vpc.default.id

  # Ingress rule for SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    self        = true # referencing the security group id itself
  }


  # Egress rule for HTTP
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    self        = true # referencing the security group id itself
  }

}

# Create a public subnet in the default VPC
resource "aws_subnet" "public_subnet" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = "172.31.96.0/20"
  # This should be a CIDR that is within the VPC CIDR and does not overlap with existing subnets
  map_public_ip_on_launch = true
  tags                    = {
    Name = "public-subnet"
    Environment = var.environment
  }
}

# Create a private subnet in the default VPC
resource "aws_subnet" "private_subnet" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = "172.31.48.0/20"
  # This should be a CIDR that is within the VPC CIDR and does not overlap with existing subnets
  map_public_ip_on_launch = false
  tags                    = {
    Name = "private-subnet"
    Environment = var.environment
  }
}

#resource "aws_internet_gateway" "internet_gw" {
#  vpc_id = data.aws_vpc.default.id
#}
#
## Create a public route table
#resource "aws_route_table" "public_route_table" {
#  vpc_id = data.aws_vpc.default.id
#
#  route {
#    cidr_block = "0.0.0.0/0"
#    gateway_id = aws_internet_gateway.internet_gw.id
#  }
#}
#
## Associate the public route table with the public subnet
#resource "aws_route_table_association" "public_route_table_association" {
#  subnet_id      = aws_subnet.public_subnet.id
#  route_table_id = aws_route_table.public_route_table.id
#}


# Create a private route table
resource "aws_route_table" "private_route_table" {
  vpc_id = data.aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name        = "my-route-table"
    Environment = var.environment
  }
}

# Associate the private route table with the private subnet
resource "aws_route_table_association" "my_route_table_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}

data "aws_ami" "latest_amz_linux_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

resource "aws_iam_policy" "allow_ec2_connect" {
  name        = "allow-ec2-instance-connect"
  description = "Policy to allow EC2 Instance Connect"

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ec2-instance-connect:SendSSHPublicKey"
        Resource = "*" # "arn:aws:ec2:your-region:your-account-id:instance/instance-id"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_ec2_connect_policy" {
  role       = "execution-role"
  policy_arn = aws_iam_policy.allow_ec2_connect.arn
}

resource "aws_iam_instance_profile" "example" {
  name = "ec2-execution-instance-profile"
  role = "execution-role"
}


resource "aws_instance" "private_instance" {
  ami                    = data.aws_ami.latest_amz_linux_ami.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private_subnet.id
  #  security_groups = [aws_security_group.private_sg.name]
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  key_name               = aws_key_pair.generated_key_pair.key_name  # Associate the key pair

  tags = {
    Name = "ec2-${var.environment}-private-instance"
  }
}

resource "aws_instance" "public_instance" {
  # In a public subnet and the associated subnet is configured to auto-assign public IPs.
  ami                         = data.aws_ami.latest_amz_linux_ami.id
  instance_type               = "t2.micro"
  #  subnet_id       = tolist(data.aws_subnets.all.ids)[0] # Using the first subnet in the VPC (rout table has a route to an Internet Gateway (IG))
  # security_groups = use default SG
  vpc_security_group_ids      = [aws_security_group.private_sg.id]
  key_name                    = aws_key_pair.generated_key_pair.key_name  # Associate the key pair
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.example.name # "ec2-execution-instance-profile"
  user_data                   = file("default.sh")
  tags                        = {
    Name = "ec2-${var.environment}-public-instance"
  }
}
# terraform plan -out=plan.out
# terraform apply plan.out && terraform output -raw private_key_pem > my_private_key.pem
# ssh -i "my_private_key.pem" ec2-user@ec2-<public-ip-address>.eu-west-2.compute.amazonaws.com

# Copy local .pem file to ec2 instance
# scp -i "my_private_key.pem" <local/path/to/file/to/copy> ec2-user@ec2-<IP-Address>.eu-west-2.compute.amazonaws.com:~/ec2/destination/file/path
# scp -i "my_private_key.pem" my_private_key.pem ec2-user@ec2-18-133-239-76.eu-west-2.compute.amazonaws.com:~/my_private_key.pem

# Using Bastion Host to establish an SSH tunnel and open an SSH session to a private ec2 instance
# ssh -i "BastionKey.pem" -A -t ec2-user@BastionPublicIP ssh -i "PrivateKey.pem" ec2-user@PrivateInstancePrivateIP

# ssh -i "my_private_key.pem" -A -t ec2-user@ec2-18-133-239-76.eu-west-2.compute.amazonaws.com ssh -i my_private_key.pem ec2-user@172.31.58.226
# The -t flag will force SSH to allocate a pseudo-terminal, useful when executing a command on the target system that requires a terminal.


# ssh -A -J user@bastion_host_ip user@private_instance_ip
# With -A SSH agent forwarding is enabled (use cautiously), and -J specifies the jump host (the bastion host in this case).


