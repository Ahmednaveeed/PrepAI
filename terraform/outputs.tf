output "ec2_public_ip" {
  description = "Public IP of the PrepAI EC2 instance"
  value       = aws_instance.prepai_server.public_ip
}