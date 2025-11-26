# VPC
resource "aws_vpc" "main" {
  cidr_block       = "172.31.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "VPC-HR"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "VPC-HR-IGW"
  }
}

# Route Table voor public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Public-RT"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }
}

# Private subnets
resource "aws_subnet" "web_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "172.31.1.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Name = "subnet_web"
  }
}

resource "aws_subnet" "db_subnet1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "172.31.2.0/24"
  availability_zone = "eu-central-1b"

  tags = {
    Name = "subnet_db1"
  }
}

resource "aws_subnet" "db_subnet2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "172.31.3.0/24"
  availability_zone = "eu-central-1c"

  tags = {
    Name = "subnet_db2"
  }
}

# public subnets
resource "aws_subnet" "lb_subnet1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "172.31.4.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet_lb1"
  }
}

resource "aws_route_table_association" "lb_subnet1_assoc" {
  subnet_id      = aws_subnet.lb_subnet1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "lb_subnet2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "172.31.5.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet_lb2"
  }
}

resource "aws_route_table_association" "lb_subnet2_assoc" {
  subnet_id      = aws_subnet.lb_subnet2.id
  route_table_id = aws_route_table.public.id
}

# Elastic IP voor NAT
resource "aws_eip" "nat" {
  tags = {
    Name = "NAT-EIP"
  }
}

# NAT Gateway in public subnet
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.lb_subnet1.id
  tags = {
    Name = "NAT-GW"
  }
}

# Route Table voor private subnets
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Private-RT"
  }

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

# Associaties private subnets
resource "aws_route_table_association" "web_subnet_assoc" {
  subnet_id      = aws_subnet.web_subnet.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "db_subnet1_assoc" {
  subnet_id      = aws_subnet.db_subnet1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "db_subnet2_assoc" {
  subnet_id      = aws_subnet.db_subnet2.id
  route_table_id = aws_route_table.private.id
}
