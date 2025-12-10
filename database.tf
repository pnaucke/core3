# Database subnet groep
resource "aws_db_subnet_group" "hr_db_subnet_group" {
  name       = "hr-db-subnet-group"
  subnet_ids = [aws_subnet.subnet_db1.id, aws_subnet.subnet_db2.id]

  tags = {
    Name = "hr-db-subnet-group"
  }
}

# RDS Parameter Group voor logging
resource "aws_db_parameter_group" "hr_db_params" {
  name   = "hr-db-general-log-params"
  family = "mysql8.0"

  parameter {
    name  = "general_log"
    value = "1"  # Zet general log aan
  }

  parameter {
    name  = "slow_query_log"
    value = "1"  # Zet slow query log aan
  }

  parameter {
    name  = "log_output"
    value = "FILE"  # Log naar bestand (nodig voor CloudWatch)
  }

  tags = {
    Name = "hr-db-params"
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
  
  db_name = "innovatech"
  username = "admin"
  password = var.db_password
  
  db_subnet_group_name   = aws_db_subnet_group.hr_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.sg_database.id]
  
  publicly_accessible    = false
  skip_final_snapshot    = true
  
  # 👇 LOGGING CONFIGURATIE 👇
  enabled_cloudwatch_logs_exports = ["general", "slowquery"]
  parameter_group_name = aws_db_parameter_group.hr_db_params.name
  monitoring_role_arn = aws_iam_role.rds_cloudwatch_role.arn

    monitoring_interval = 60
  
  tags = {
    Name = "hr-database"
  }
}

# tables
resource "null_resource" "create_tables" {
  depends_on = [aws_db_instance.hr_database]

  provisioner "local-exec" {
    command = <<EOT
      sleep 30
      mysql -h ${replace(aws_db_instance.hr_database.endpoint, ":3306", "")} \
        -u admin \
        -p'${var.db_password}' \
        -e "
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
          
          INSERT INTO hr (name, password) 
          VALUES ('admin', '${var.hr_password}');
        "
    EOT
  }
}