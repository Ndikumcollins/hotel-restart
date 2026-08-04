terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Automatically find the latest official Ubuntu 22.04 AMI in this region
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Official Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Key Pair using your existing SSH key
resource "aws_key_pair" "deployer" {
  key_name   = "hotel-app-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

# Security Group opening SSH (22) and HTTP (80)
resource "aws_security_group" "hotel_sg" {
  name        = "hotel-app-security-group"
  description = "Allow SSH and HTTP inbound traffic"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance
resource "aws_instance" "hotel_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.deployer.key_name

  security_groups = [aws_security_group.hotel_sg.name]

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install -y docker.io git
              sudo systemctl start docker
              sudo systemctl enable docker

              cd /home/ubuntu
              git clone https://github.com/Ndikumcollins/hotel-restart.git
              cd hotel-restart
              sudo docker build -t hotel-restart-app .
              sudo docker run -d --name hotel-container -p 80:80 hotel-restart-app
              EOF

  tags = {
    Name = "Hotel-App-Server"
  }
}

output "public_ip" {
  value       = aws_instance.hotel_server.public_ip
  description = "The public IP address of the hotel application server"
}
