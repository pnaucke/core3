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

# MySQL Provider configuratie
provider "mysql" {
  endpoint = aws_db_instance.db.address
  username = "admin"
  password = var.db_password
}

# Database aanmaken - MET DUMMY WAARDE OM AFHANKELIJKHEID TE FORCEREN
resource "mysql_database" "innovatech" {
  name = "innovatech"
  
  # Wacht op RDS en security groups via een dummy trigger
  provisioner "local-exec" {
    command = "echo 'Waiting for RDS to be ready...' && sleep 30"
    
    # Deze triggers zorgen ervoor dat we wachten op de juiste resources
    when = create
  }
  
  # Lifecycle om te zorgen dat de provider eerst kan initialiseren
  lifecycle {
    precondition {
      condition     = aws_db_instance.db.status == "available"
      error_message = "RDS database must be in 'available' status before creating MySQL resources"
    }
  }
  
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

# Simpele null_resource die wacht tot alles klaar is
resource "null_resource" "wait_for_rds" {
  triggers = {
    rds_id = aws_db_instance.db.id
  }
  
  provisioner "local-exec" {
    command = <<EOT
      echo "Wachten op RDS database..."
      sleep 120  # Wacht 2 minuten voor RDS om op te starten
    EOT
  }
  
  depends_on = [
    aws_db_instance.db,
    aws_security_group.db_sg,
    aws_security_group.web_sg
  ]
}

# Tabellen aanmaken - PAS NADAT wait_for_rds klaar is
resource "null_resource" "create_tables" {
  triggers = {
    always_run = timestamp()
  }
  
  provisioner "local-exec" {
    command = <<EOT
      echo "Proberen tabellen aan te maken..."
      
      # Probeer maximaal 10 keer met 30 seconden interval
      for i in {1..10}; do
        echo "Poging $i..."
        
        if mysql -h ${aws_db_instance.db.address} -u admin -p"${var.db_password}" -e "SELECT 1;" 2>/dev/null; then
          echo "Database is beschikbaar!"
          
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
          
          echo "Tabellen succesvol aangemaakt!"
          exit 0
        fi
        
        echo "Database nog niet beschikbaar, wachten 30 seconden..."
        sleep 30
      done
      
      echo "FOUT: Kon geen verbinding maken met database na 10 pogingen"
      exit 1
    EOT
  }
  
  depends_on = [
    null_resource.wait_for_rds,
    mysql_grant.admin_grant
  ]
}