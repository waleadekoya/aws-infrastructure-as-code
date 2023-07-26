# Create a VPC
resource "aws_vpc" "main" {
  cidr_block   = var.cidr_block
  tags         = {
    Name = "${var.vpc_name}-${var.environment}"
  }
}

# Creates a private Subnet
resource "aws_subnet" "main" {
  # In AWS, the subnet is private by default.
  vpc_id     = aws_vpc.main.id
  cidr_block = var.subnet_cidr_block
  tags       = {
    Name = "${var.subnet_name}-private-${var.environment}"
  }
}

# Creates a public Subnet
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_cidr_block # Must be a subset of the VPC's CIDR block
  tags       = {
    Name = "${var.subnet_name}-public-${var.environment}"
  }
}

# Creates Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = {
    Name = "${var.gateway_name}-${var.environment}"
  }
}

# Route table
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "${var.route_table_name}-private-${var.environment}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "${var.route_table_name}-public-${var.environment}"
  }
}

# Associate the route table to the subnet
resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}


resource "aws_route_table_association" "public" {
  # In the code above, the aws_subnet.public resource creates a public subnet.
  # By associating it with a route table `aws_route_table.public` that has a route to an Internet Gateway `aws_internet_gateway.main`.
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
