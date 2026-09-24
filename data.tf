data "aws_vpc" "existing" {
  filter {
    name   = "tag:Name"
    values = ["${var.prefix}-vpc"]
  }
}

data "aws_subnet" "public1" {
  filter {
    name   = "tag:Name"
    values = ["${var.prefix}-public-subnet1"]
  }
}

data "aws_subnet" "public2" {
  filter {
    name   = "tag:Name"
    values = ["${var.prefix}-public-subnet2"]
  }
}

data "aws_security_group" "ssh" {
  filter {
    name   = "group-name"
    values = ["${var.prefix}-sg-ssh"]
  }
}

data "aws_security_group" "http" {
  filter {
    name   = "group-name"
    values = ["${var.prefix}-sg-http"]
  }
}

data "aws_security_group" "lb" {
  filter {
    name   = "group-name"
    values = ["${var.prefix}-sg-lb"]
  }
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}