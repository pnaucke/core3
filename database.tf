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

# Users tabel aanmaken
resource "mysql_query" "create_users_table" {
  query = <<-SQL
    CREATE TABLE IF NOT EXISTS users (
      id INT(5) AUTO_INCREMENT PRIMARY KEY,
      name VARCHAR(50),
      email VARCHAR(50),
      department VARCHAR(50),
      status VARCHAR(50),
      role VARCHAR(50)
    )
  SQL
  
  depends_on = [mysql_grant.admin_grant]
}

# HR tabel voor login aanmaken
resource "mysql_query" "create_hr_table" {
  query = <<-SQL
    CREATE TABLE IF NOT EXISTS hr (
      name VARCHAR(50) NOT NULL,
      password VARCHAR(50)
    )
  SQL
  
  depends_on = [mysql_grant.admin_grant]
}

# Standaard HR gebruikers toevoegen
resource "mysql_query" "seed_hr_users" {
  query = <<-SQL
    INSERT IGNORE INTO hr (name, password) VALUES 
    ('admin', 'admin123'),
    ('hr', 'hr123')
  SQL
  
  depends_on = [mysql_query.create_hr_table]
}