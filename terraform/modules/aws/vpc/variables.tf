variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
}

variable "subnet_cidr_block" {
  description = "The CIDR block for the subnet"
  type        = string
}

variable "subnet_name" {
  description = "The name to give the subnet"
  type        = string
}

variable "gateway_name" {
  description = "The name to give the internet gateway"
  type        = string
}

variable "environment" {
  description = "The environment in which the VPC is being created"
  type        = string
}

variable "route_table_name" {
  description = "The name to give the route table"
  type        = string
}

variable "public_subnet_cidr_block" {
  default = ""
}
