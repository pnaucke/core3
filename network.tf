# ----------------------
# VPC
# ----------------------
resource "aws_vpc" "main_vpc" {
  cidr_block           = "172.31.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "VPC-HR" }
}

# ----------------------
# Subnets Web
# ----------------------
resource "aws_subnet" "web1_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "172.31.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true
  tags = { Name = "subnet_web_public1" }
}

resource "aws_subnet" "web2_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "172.31.11.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = true
  tags = { Name = "subnet_web_public2" }
}

# ----------------------
# Subnets Database
# ----------------------
resource "aws_subnet" "db_subnet1" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "172.31.21.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = false
  tags = { Name = "subnet_db_private1" }
}

resource "aws_subnet" "db_subnet2" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "172.31.22.0/24"
  availability_zone       = "eu-central-1c"
  map_public_ip_on_launch = false
  tags = { Name = "subnet_db_private2" }
}

# ----------------------
# Internet Gateway
# ----------------------
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = { Name = "VPC-HR-IGW" }
}

# ----------------------
# Route Table voor public subnets
# ----------------------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }
  tags = { Name = "public-rt" }
}

# Associate route table met public subnets
resource "aws_route_table_association" "web1_assoc" {
  subnet_id      = aws_subnet.web1_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "web2_assoc" {
  subnet_id      = aws_subnet.web2_subnet.id
  route_table_id = aws_route_table.public_rt.id
}
