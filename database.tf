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
  endpoint = split(":", aws_db_instance.db.endpoint)[0]  # Alleen hostname, geen port
  username = "admin"
  password = var.db_password
}

# Tabellen aanmaken in de database
resource "mysql_database" "innovatech" {
  name = "innovatech"
}

resource "mysql_user" "admin_user" {
  user               = "admin"
  host               = "%"
  plaintext_password = var.db_password
}

resource "mysql_grant" "admin_grant" {
  user       = mysql_user.admin_user.user
  host       = mysql_user.admin_user.host
  database   = mysql_database.innovatech.name
  privileges = ["ALL"]
  depends_on = [mysql_database.innovatech, mysql_user.admin_user]
}

# Users tabel
resource "mysql_table" "users" {
  database = mysql_database.innovatech.name
  name     = "users"
  
  column {
    name     = "id"
    type     = "INT"
    size     = 5
    null     = false
    key      = "PRI"
    extra    = "AUTO_INCREMENT"
  }
  
  column {
    name = "name"
    type = "VARCHAR"
    size = 50
  }
  
  column {
    name = "email"
    type = "VARCHAR"
    size = 50
  }
  
  column {
    name = "department"
    type = "VARCHAR"
    size = 50
  }
  
  column {
    name = "status"
    type = "VARCHAR"
    size = 50
  }
  
  column {
    name = "role"
    type = "VARCHAR"
    size = 50
  }
  
  depends_on = [mysql_grant.admin_grant]
}

# HR tabel voor login
resource "mysql_table" "hr" {
  database = mysql_database.innovatech.name
  name     = "hr"
  
  column {
    name = "name"
    type = "VARCHAR"
    size = 50
    null = false
  }
  
  column {
    name = "password"
    type = "VARCHAR"
    size = 50
  }
  
  depends_on = [mysql_grant.admin_grant]
}

# Voeg een standaard HR gebruiker toe
resource "null_resource" "seed_hr_user" {
  triggers = {
    db_endpoint = aws_db_instance.db.endpoint
  }
  
  provisioner "local-exec" {
    command = <<EOT
      mysql -h ${split(":", aws_db_instance.db.endpoint)[0]} -u admin -p"${var.db_password}" -D innovatech <<MYSQL
      INSERT IGNORE INTO hr (name, password) VALUES ('admin', 'admin123');
      INSERT IGNORE INTO hr (name, password) VALUES ('hr', 'hr123');
      MYSQL
    EOT
  }
  
  depends_on = [mysql_table.hr]
}