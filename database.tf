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
  
  # Database naam
  db_name = "innovatech"
  
  # Credentials
  username = "admin"
  password = "admin123!"
  
  # Network configuratie
  db_subnet_group_name   = aws_db_subnet_group.hr_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.sg_database.id]
  
  # Externe toegang
  publicly_accessible    = true
  
  # General
  skip_final_snapshot    = true
  
  tags = {
    Name = "hr-database"
  }
}

# Tabbles
resource "null_resource" "create_tables" {
  depends_on = [aws_db_instance.hr_database]

  provisioner "local-exec" {
    command = <<EOT
      mysql -h ${aws_db_instance.hr_database.endpoint} -u admin -p'admin123!' -e "
        CREATE DATABASE IF NOT EXISTS innovatech;
        USE innovatech;
        
        CREATE TABLE IF NOT EXISTS users (
          id INT(5) AUTO_INCREMENT PRIMARY KEY,
          name VARCHAR(50),
          email VARCHAR(50),
          department VARCHAR(50),
          status VARCHAR(50),
          role VARCHAR(50)
        );
        
        CREATE TABLE IF NOT EXISTS hr (
          name VARCHAR(50),
          password VARCHAR(50)
        );
        
        INSERT INTO hr (name, password) VALUES ('admin', 'admin123');
      "
    EOT
  }
}