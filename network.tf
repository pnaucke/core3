# VPC
resource "aws_vpc" "hr_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "VPC-HR" }
}

# Public subnet for webserver
resource "aws_subnet" "subnet_web_public" {
  vpc_id                  = aws_vpc.hr_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-central-1a"
  tags = { Name = "subnet_web_public" }
}

# Private subnet for DB
resource "aws_subnet" "subnet_db_private" {
  vpc_id                  = aws_vpc.hr_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "eu-central-1b"
  tags = { Name = "subnet_db_private" }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.hr_vpc.id
  tags   = { Name = "VPC-HR-IGW" }
}

# Route table for public subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.hr_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "public-rt" }
}

# Associate public subnet with route table
resource "aws_route_table_association" "web_assoc" {
  subnet_id      = aws_subnet.subnet_web_public.id
  route_table_id = aws_route_table.public_rt.id
}
