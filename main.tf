terraform {
  backend "remote" {
    organization = "me_myself"
    workspaces {
      name = "Test"
    }
  }
}

provider "hcp" {
  client_secret = var.tf-secret-key
}

provider "aws" {
  region = "us-east-2"
  access_key = var.access_key
  secret_key = var.secret_key
}

data "aws_vpc" "name" {
  default = true
}

data "aws_subnet" "sub" {
  vpc_id = data.aws_vpc.name
  filter {
    name = "availability-zone"
    values = ["us-east-2a"]
  }
}

resource "aws_security_group" "sg-test" {
  vpc_id = data.aws_vpc.name
  description = "sg for test vpc"
  name = "web-sg-test"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ec2" {
  ami = "ami-0d8c288225dc75373"
  instance_type = "t2.micro"
  key_name = "ohio"
  subnet_id = data.aws_subnet.sub
  vpc_security_group_ids = [aws_security_group.sg-test.id]
  associate_public_ip_address = true

  user_data = file("${path.module}/userdata.sh")

  tags = {
    name = "test"
  }
}

output "instance_ip" {
  value = aws_instance.ec2.public_ip
}