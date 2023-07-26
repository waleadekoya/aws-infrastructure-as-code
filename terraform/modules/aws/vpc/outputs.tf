#  In Terraform, if you want to access a module's attributes outside the module itself, declare them as outputs.
output "id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id  # replace aws_vpc.example with your VPC resource name
}

output "public_subnet_id" {
  description = "The ID of the public subnet"
  value       = aws_subnet.public.id
}
