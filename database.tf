resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = [aws_subnet.db_subnet1.id, aws_subnet.db_subnet2.id]
  tags = { Name = "db-subnet-group" }
}

resource "aws_db_instance" "db" {
  identifier              = "mydb-${random_id.suffix.hex}"
  allocated_storage       = 20
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  db_name                 = "innovatech"
  username                = "admin"
  password                = var.db_password
  parameter_group_name    = "default.mysql8.0"
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.db_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.db_subnet_group.name
  publicly_accessible     = false
  
  apply_immediately       = true
  
  tags = { Name = "Database" }
}

# Database setup - GECORRIGEERDE VERSIE
resource "null_resource" "setup_database" {
  triggers = {
    rds_instance_id = aws_db_instance.db.id
    db_password     = var.db_password
    always_run      = timestamp()
  }
  
  provisioner "local-exec" {
    command = <<EOT
      echo "=== DATABASE SETUP START ==="
      
      # Variabelen - gebruik ESCAPED syntax
      DB_HOST="${aws_db_instance.db.address}"
      DB_PASS="${var.db_password}"
      
      echo "Database host: $DB_HOST"
      
      # STAP 1: Wacht op RDS (eenvoudige versie)
      echo "STAP 1: Wachten op RDS database (kan 10 min duren)..."
      sleep 600  # Wacht 10 minuten
      
      # STAP 2: Database verifiëren
      echo "STAP 2: Database verifiëren..."
      mysql -h "$DB_HOST" -u admin -p"$DB_PASS" -e "CREATE DATABASE IF NOT EXISTS innovatech;" || echo "Database bestaat al of kan niet gemaakt worden"
      
      # STAP 3: Users tabel
      echo "STAP 3: Users tabel aanmaken..."
      mysql -h "$DB_HOST" -u admin -p"$DB_PASS" innovatech <<SQL
CREATE TABLE IF NOT EXISTS users (
  id INT(5) AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50),
  email VARCHAR(50),
  department VARCHAR(50),
  status VARCHAR(50),
  role VARCHAR(50)
);
SQL
      
      # STAP 4: HR tabel
      echo "STAP 4: HR tabel aanmaken..."
      mysql -h "$DB_HOST" -u admin -p"$DB_PASS" innovatech <<SQL
CREATE TABLE IF NOT EXISTS hr (
  name VARCHAR(50) NOT NULL,
  password VARCHAR(50)
);
SQL
      
      # STAP 5: Standaard gebruikers
      echo "STAP 5: Standaard gebruikers toevoegen..."
      mysql -h "$DB_HOST" -u admin -p"$DB_PASS" innovatech <<SQL
INSERT IGNORE INTO hr (name, password) VALUES 
('admin', 'admin123'),
('hr', 'hr123');
SQL
      
      echo "=== DATABASE SETUP COMPLEET ==="
      echo "Database: innovatech"
      echo "Host: $DB_HOST"
      echo "Gebruikers: admin/admin123, hr/hr123"
    EOT
  }
  
  depends_on = [
    aws_db_instance.db,
    aws_security_group.db_sg,
    aws_security_group.web_sg
  ]
}