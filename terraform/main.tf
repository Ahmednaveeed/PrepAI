terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ── VPC ────────────────────────────────────────────
resource "aws_vpc" "prepai_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "prepai-vpc" }
}

# ── Public Subnet ──────────────────────────────────
resource "aws_subnet" "prepai_subnet" {
  vpc_id                  = aws_vpc.prepai_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"
  tags = { Name = "prepai-subnet" }
}

# ── Internet Gateway ───────────────────────────────
resource "aws_internet_gateway" "prepai_igw" {
  vpc_id = aws_vpc.prepai_vpc.id
  tags = { Name = "prepai-igw" }
}

# ── Route Table ────────────────────────────────────
resource "aws_route_table" "prepai_rt" {
  vpc_id = aws_vpc.prepai_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.prepai_igw.id
  }
  tags = { Name = "prepai-rt" }
}

resource "aws_route_table_association" "prepai_rta" {
  subnet_id      = aws_subnet.prepai_subnet.id
  route_table_id = aws_route_table.prepai_rt.id
}

# ── Security Group ─────────────────────────────────
resource "aws_security_group" "prepai_sg" {
  name        = "prepai-sg"
  description = "Allow SSH, HTTP, app ports"
  vpc_id      = aws_vpc.prepai_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "prepai-sg" }
}

# ── EC2 Instance ───────────────────────────────────
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "prepai_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.prepai_subnet.id
  vpc_security_group_ids = [aws_security_group.prepai_sg.id]
  key_name               = var.key_name

  root_block_device {
    volume_size = 30
  }

  tags = { Name = "prepai-server" }
}