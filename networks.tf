resource "aws_vpc" "hr_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "VPC-HR" }
}

resource "aws_subnet" "web_public" {
  vpc_id                  = aws_vpc.hr_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = { Name = "subnet_web_public" }
}

resource "aws_subnet" "db_private" {
  vpc_id            = aws_vpc.hr_vpc.id
  cidr_block        = "10.0.2.0/24"
  tags = { Name = "subnet_db_private" }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.hr_vpc.id
  tags   = { Name = "VPC-HR-IGW" }
}

# Route Table voor public subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.hr_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "public-rt" }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.web_public.id
  route_table_id = aws_route_table.public_rt.id
}
