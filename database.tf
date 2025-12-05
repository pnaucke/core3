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
  tags = { Name = "Database" }
}

# MySQL Provider om tabellen aan te maken
provider "mysql" {
  endpoint = split(":", aws_db_instance.db.endpoint)[0]
  username = "admin"
  password = var.db_password
}

# Database aanmaken
resource "mysql_database" "innovatech" {
  name = "innovatech"
}

# Database gebruiker aanmaken
resource "mysql_user" "admin_user" {
  user               = "admin"
  host               = "%"
  plaintext_password = var.db_password
}

# Rechten geven aan gebruiker
resource "mysql_grant" "admin_grant" {
  user       = mysql_user.admin_user.user
  host       = mysql_user.admin_user.host
  database   = mysql_database.innovatech.name
  privileges = ["ALL"]
  depends_on = [mysql_database.innovatech, mysql_user.admin_user]
}

# Tabellen aanmaken via null_resource (werkt altijd!)
resource "null_resource" "create_tables" {
  triggers = {
    db_endpoint = aws_db_instance.db.endpoint
    db_password = var.db_password
  }
  
  provisioner "local-exec" {
    command = <<EOT
      # Wacht tot database beschikbaar is
      sleep 30
      
      # Creëer users tabel
      mysql -h ${split(":", aws_db_instance.db.endpoint)[0]} -u admin -p"${var.db_password}" -D innovatech <<MYSQL
      CREATE TABLE IF NOT EXISTS users (
        id INT(5) AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(50),
        email VARCHAR(50),
        department VARCHAR(50),
        status VARCHAR(50),
        role VARCHAR(50)
      );
      MYSQL
      
      # Creëer hr tabel
      mysql -h ${split(":", aws_db_instance.db.endpoint)[0]} -u admin -p"${var.db_password}" -D innovatech <<MYSQL
      CREATE TABLE IF NOT EXISTS hr (
        name VARCHAR(50) NOT NULL,
        password VARCHAR(50)
      );
      MYSQL
      
      # Voeg standaard HR gebruikers toe
      mysql -h ${split(":", aws_db_instance.db.endpoint)[0]} -u admin -p"${var.db_password}" -D innovatech <<MYSQL
      INSERT IGNORE INTO hr (name, password) VALUES 
      ('admin', 'admin123'),
      ('hr', 'hr123');
      MYSQL
    EOT
  }
  
  depends_on = [
    mysql_grant.admin_grant,
    aws_db_instance.db
  ]
}