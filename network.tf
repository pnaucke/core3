# VPC
resource "aws_vpc" "hr" {
  cidr_block           = "172.31.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "VPC-HR"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "hr_igw" {
  vpc_id = aws_vpc.hr.id

  tags = {
    Name = "igw-hr"
  }
}

# Main route table
resource "aws_default_route_table" "main" {
  default_route_table_id = aws_vpc.hr.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hr_igw.id
  }

  tags = {
    Name = "main-rt"
  }
}

# Database subnets (PRIVATE)
resource "aws_subnet" "subnet_db1" {
  vpc_id                  = aws_vpc.hr.id
  cidr_block              = "172.31.2.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "subnet_db1"
  }
}

resource "aws_subnet" "subnet_db2" {
  vpc_id                  = aws_vpc.hr.id
  cidr_block              = "172.31.3.0/24"
  availability_zone       = "eu-central-1c"
  map_public_ip_on_launch = false

  tags = {
    Name = "subnet_db2"
  }
}

# Webserver subnet (PRIVATE)
resource "aws_subnet" "subnet_web1" {
  vpc_id                  = aws_vpc.hr.id
  cidr_block              = "172.31.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "subnet_web1"
  }
}

resource "aws_subnet" "subnet_web2" {
  vpc_id            = aws_vpc.hr.id
  cidr_block        = "172.31.7.0/24"
  availability_zone = "eu-central-1b"
  map_public_ip_on_launch = false
  tags = { Name = "subnet_web2" }
}

# Load balancer subnets (PUBLIC)
resource "aws_subnet" "subnet_lb1" {
  vpc_id                  = aws_vpc.hr.id
  cidr_block              = "172.31.4.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet_lb1"
  }
}

resource "aws_subnet" "subnet_lb2" {
  vpc_id                  = aws_vpc.hr.id
  cidr_block              = "172.31.5.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet_lb2"
  }
}