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
  vpc_security_group_ids  = [aws_security_group.db_sg.id]  # Security group uit security.tf
  db_subnet_group_name    = aws_db_subnet_group.db_subnet_group.name
  publicly_accessible     = false
  
  # Voeg timeouts toe
  apply_immediately       = true
  
  tags = { Name = "Database" }
}

# MySQL Provider om tabellen aan te maken - WACHT OP RDS EN SECURITY GROUPS
provider "mysql" {
  endpoint = aws_db_instance.db.address
  username = "admin"
  password = var.db_password
  
  # BELANGRIJK: Wacht tot security group EN RDS ready zijn
  depends_on = [
    aws_security_group.db_sg,    # Security group moet bestaan
    aws_db_instance.db           # RDS moet running zijn
  ]
}

# Database aanmaken
resource "mysql_database" "innovatech" {
  name = "innovatech"
  
  # Wacht tot provider kan connecten
  depends_on = [
    aws_security_group.db_sg,
    aws_db_instance.db
  ]
  
  # Langer timeout voor RDS
  timeouts {
    create = "20m"
    delete = "20m"
  }
}

# Database gebruiker aanmaken
resource "mysql_user" "admin_user" {
  user               = "admin"
  host               = "%"
  plaintext_password = var.db_password
  
  depends_on = [
    mysql_database.innovatech
  ]
  
  timeouts {
    create = "15m"
  }
}

# Rechten geven aan gebruiker
resource "mysql_grant" "admin_grant" {
  user       = mysql_user.admin_user.user
  host       = mysql_user.admin_user.host
  database   = mysql_database.innovatech.name
  privileges = ["ALL"]
  
  depends_on = [
    mysql_database.innovatech,
    mysql_user.admin_user
  ]
}

# Tabellen aanmaken via null_resource
resource "null_resource" "create_tables" {
  triggers = {
    db_endpoint = aws_db_instance.db.endpoint
    db_password = var.db_password
    always_run  = timestamp()  # Forceer altijd run
  }
  
  provisioner "local-exec" {
    command = <<EOT
      echo "Wachten op RDS database beschikbaarheid..."
      
      # Wacht maximaal 5 minuten
      timeout=300
      interval=10
      elapsed=0
      
      while [ $elapsed -lt $timeout ]; do
        if mysql -h ${aws_db_instance.db.address} -u admin -p"${var.db_password}" -e "SELECT 1;" 2>/dev/null; then
          echo "✓ Database is beschikbaar na ${elapsed} seconden"
          
          # Creëer users tabel
          mysql -h ${aws_db_instance.db.address} -u admin -p"${var.db_password}" -D innovatech <<MYSQL
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
          mysql -h ${aws_db_instance.db.address} -u admin -p"${var.db_password}" -D innovatech <<MYSQL
          CREATE TABLE IF NOT EXISTS hr (
            name VARCHAR(50) NOT NULL,
            password VARCHAR(50)
          );
          MYSQL
          
          # Voeg standaard HR gebruikers toe
          mysql -h ${aws_db_instance.db.address} -u admin -p"${var.db_password}" -D innovatech <<MYSQL
          INSERT IGNORE INTO hr (name, password) VALUES 
          ('admin', 'admin123'),
          ('hr', 'hr123');
          MYSQL
          
          echo "✓ Tabellen succesvol aangemaakt!"
          exit 0
        fi
        
        echo "Wachten... ($((elapsed)) seconden)"
        sleep $interval
        elapsed=$((elapsed + interval))
      done
      
      echo "✗ Timeout: Database niet beschikbaar na $timeout seconden"
      exit 1
    EOT
  }
  
  depends_on = [
    mysql_grant.admin_grant,
    aws_db_instance.db,
    aws_security_group.db_sg,
    aws_security_group.web_sg  # Web SG moet ook bestaan voor connectie
  ]
}