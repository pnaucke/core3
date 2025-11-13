# ----------------------
# Database Subnets
# ----------------------
resource "aws_subnet" "db_subnet1" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "172.31.2.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = false
  tags = { Name = "subnet_db_private1" }
}

resource "aws_subnet" "db_subnet2" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "172.31.3.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = false
  tags = { Name = "subnet_db_private2" }
}

# ----------------------
# DB Subnet Group
# ----------------------
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = [aws_subnet.db_subnet1.id, aws_subnet.db_subnet2.id]
  tags       = { Name = "db-subnet-group" }
}

# ----------------------
# RDS Database
# ----------------------
resource "aws_db_instance" "db" {
  identifier              = "hr-db-${random_id.suffix.hex}"
  allocated_storage       = 20
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  db_name                 = "hrdb"
  username                = "admin"
  password                = var.db_password
  parameter_group_name    = "default.mysql8.0"
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.db_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.db_subnet_group.name
  publicly_accessible     = false
  tags = { Name = "HR Database" }
}
