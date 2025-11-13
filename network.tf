# VPC
resource "aws_vpc" "main" {
  cidr_block       = "172.31.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "VPC-HR"
  }
}

# Subnets
resource "aws_subnet" "web_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "172.31.1.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Name = "subnet_web_public"
  }
}

resource "aws_subnet" "db_subnet1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "172.31.2.0/24"
  availability_zone = "eu-central-1b"

  tags = {
    Name = "subnet_db_private1"
  }
}

resource "aws_subnet" "db_subnet2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "172.31.3.0/24"
  availability_zone = "eu-central-1c"

  tags = {
    Name = "subnet_db_private2"
  }
}
