# Database subnet groep
resource "aws_db_subnet_group" "hr_db_subnet_group" {
  name       = "hr-db-subnet-group"
  subnet_ids = [aws_subnet.subnet_db1.id, aws_subnet.subnet_db2.id]

  tags = {
    Name = "hr-db-subnet-group"
  }
}

# RDS MySQL database
resource "aws_db_instance" "hr_database" {
  identifier           = "hr-database"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  storage_type         = "gp2"
  
  # Credentials
  username = "admin"
  password = "admin123!"
  
  # Network configuratie
  db_subnet_group_name   = aws_db_subnet_group.hr_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.sg_database.id]
  
  # Externe toegang (dit geeft de database een public IP)
  publicly_accessible    = true
  
  # General
  skip_final_snapshot    = true
  
  tags = {
    Name = "hr-database"
  }
}