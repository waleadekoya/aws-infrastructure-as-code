output "instance_public_ip" {
  description = "The public IP of the created instance"
  value       = aws_instance.example.public_ip
}

output "aws_ami" {
  description = "The AMI image for Linux"
  value       = data.aws_ami.latest_amz_linux_ami.id
}

