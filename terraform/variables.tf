variable "aws_region" {
  description = "AWS region to deploy into"
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.medium"
}

variable "key_name" {
  description = "Name of your AWS key pair for SSH access"
  type        = string
}

variable "my_ip" {
  description = "Your local IP for SSH access"
  type        = string
}