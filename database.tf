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
}

# Wacht op RDS en security groups voordat we tabellen aanmaken
resource "null_resource" "wait_for_rds" {
  triggers = {
    rds_id = aws_db_instance.db.id
    sg_id  = aws_security_group.db_sg.id
  }
  
  provisioner "local-exec" {
    command = <<EOT
      echo "Wachten op RDS database om op te starten..."
      echo "Dit kan 10-15 minuten duren..."
      
      # Wacht minimaal 2 minuten
      sleep 120
      
      echo "Controleer database connectie..."
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
      echo "=== TABELLEN AANMAKEN PROCES ==="
      
      DB_HOST="${aws_db_instance.db.address}"
      DB_PASS="${var.db_password}"
      
      # Probeer verbinding te maken (max 20 pogingen, elke 30 seconden = 10 minuten)
      MAX_RETRIES=20
      RETRY_INTERVAL=30
      
      for ((i=1; i<=MAX_RETRIES; i++)); do
        echo "Poging $i/$MAX_RETRIES om verbinding te maken..."
        
        if mysql -h $DB_HOST -u admin -p"$DB_PASS" -e "SELECT 1;" 2>/dev/null; then
          echo "✓ Verbinding succesvol!"
          
          # Creëer users tabel
          echo "Users tabel aanmaken..."
          mysql -h $DB_HOST -u admin -p"$DB_PASS" -D innovatech <<MYSQL
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
          echo "HR tabel aanmaken..."
          mysql -h $DB_HOST -u admin -p"$DB_PASS" -D innovatech <<MYSQL
          CREATE TABLE IF NOT EXISTS hr (
            name VARCHAR(50) NOT NULL,
            password VARCHAR(50)
          );
          MYSQL
          
          # Voeg standaard HR gebruikers toe
          echo "Standaard gebruikers toevoegen..."
          mysql -h $DB_HOST -u admin -p"$DB_PASS" -D innovatech <<MYSQL
          INSERT IGNORE INTO hr (name, password) VALUES 
          ('admin', 'admin123'),
          ('hr', 'hr123');
          MYSQL
          
          echo "=== TABELLEN SUCCESVOL AANGEMAAKT ==="
          exit 0
        else
          echo "× Geen verbinding, wachten $RETRY_INTERVAL seconden..."
          sleep $RETRY_INTERVAL
        fi
      done
      
      echo "=== FOUILLAGE: Kon geen verbinding maken na $MAX_RETRIES pogingen ==="
      echo "Controleer:"
      echo "1. Is RDS instance running?"
      echo "2. Zijn security groups correct?"
      echo "3. Is het wachtwoord correct?"
      exit 1
    EOT
  }
  
  depends_on = [
    null_resource.wait_for_rds,
    mysql_database.innovatech,
    mysql_grant.admin_grant
  ]
}