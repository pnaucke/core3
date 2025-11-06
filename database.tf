# DB Subnet Group (1 subnet, werkt zoals in oud project)
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = [aws_subnet.subnet_db_private.id]
}

# DB wachtwoord uit GitHub secret
variable "DB_PASSWORD" {
  description = "Database password from GitHub secret"
  type        = string
  sensitive   = true
}

# RDS Database
resource "aws_db_instance" "db" {
  identifier              = "mydb-${random_id.suffix.hex}"
  allocated_storage       = 20
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  db_name                 = "myappdb"
  username                = "admin"
  password                = var.DB_PASSWORD
  parameter_group_name    = "default.mysql8.0"
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.db_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.db_subnet_group.name
  publicly_accessible     = false
  tags = { Name = "HR-Database" }
}
