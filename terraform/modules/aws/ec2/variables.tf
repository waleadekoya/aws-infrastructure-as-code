variable "region" {
  description = "The region to create resources in"
  default     = "us-west-2"
}

variable "environment" {
  type        = string
  default     = "dev"
}

variable "instance_type" {
  description = "The instance type for the EC2 instances"
  type        = string
  default     = "t2.micro" # var.environment == "prod" ? "t2.large" : "t2.micro" #"t2.micro"
}


variable "tags" {
  description = "The tag name to be assigned for the EC2 instances"
  type        = map(string)
  default     = { }
}


variable "user_data_file" {
  description = "Path to the user data script file"
  type        = string
  default     = "default.sh" // File must exist and be effectively a no-op
}

variable "vpc_security_group_ids" {
  description = "List of Security Group IDs to associate with the EC2 instance"
  type        = list(string)
  default     = []
}

variable "subnet_id" {
  description = "ID of the subnet where the EC2 instance will be created"
  type        = string
}

