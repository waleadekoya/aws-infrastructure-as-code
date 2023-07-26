variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
}

variable "environment" {
  description = "The environment in which the VPC is being created"
  type        = string
}
