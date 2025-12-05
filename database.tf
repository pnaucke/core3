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
  db_name                 = "innovatech"  # Database naam wordt hier gezet
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

# VERWIJDER de hele MySQL provider en resources
# Gebruik alleen null_resource voor database setup

# Wacht op RDS om volledig op te starten
resource "null_resource" "setup_database" {
  triggers = {
    rds_instance_id = aws_db_instance.db.id
    db_password     = var.db_password
  }
  
  provisioner "local-exec" {
    command = <<EOT
      echo "=== DATABASE SETUP PROCES ==="
      echo "Dit kan 10-15 minuten duren voor RDS klaar is..."
      
      DB_HOST="${aws_db_instance.db.address}"
      DB_PASS="${var.db_password}"
      
      # STAP 1: Wacht tot RDS beschikbaar is (max 20 minuten)
      echo "STAP 1: Wachten op RDS..."
      MAX_WAIT=1200  # 20 minuten in seconden
      WAIT_INTERVAL=30
      elapsed=0
      connected=false
      
      while [ $elapsed -lt $MAX_WAIT ]; do
        echo "  Poging: $((elapsed/60))m $((elapsed%60))s verstreken..."
        
        if mysql -h $DB_HOST -u admin -p"$DB_PASS" -e "SELECT 1;" 2>/dev/null; then
          echo "  ✓ RDS is beschikbaar!"
          connected=true
          break
        fi
        
        echo "  × Nog niet beschikbaar, wachten $WAIT_INTERVAL seconden..."
        sleep $WAIT_INTERVAL
        elapsed=$((elapsed + WAIT_INTERVAL))
      done
      
      if [ "$connected" = false ]; then
        echo "FOUT: RDS niet beschikbaar na $((MAX_WAIT/60)) minuten"
        exit 1
      fi
      
      # STAP 2: Database aanmaken (als die niet al bestaat via db_name parameter)
      echo "STAP 2: Database verifiëren..."
      mysql -h $DB_HOST -u admin -p"$DB_PASS" -e "CREATE DATABASE IF NOT EXISTS innovatech;"
      
      # STAP 3: Users tabel aanmaken
      echo "STAP 3: Users tabel aanmaken..."
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
      
      # STAP 4: HR tabel aanmaken
      echo "STAP 4: HR tabel aanmaken..."
      mysql -h $DB_HOST -u admin -p"$DB_PASS" -D innovatech <<MYSQL
      CREATE TABLE IF NOT EXISTS hr (
        name VARCHAR(50) NOT NULL,
        password VARCHAR(50)
      );
      MYSQL
      
      # STAP 5: Standaard HR gebruikers toevoegen
      echo "STAP 5: Standaard gebruikers toevoegen..."
      mysql -h $DB_HOST -u admin -p"$DB_PASS" -D innovatech <<MYSQL
      INSERT IGNORE INTO hr (name, password) VALUES 
      ('admin', 'admin123'),
      ('hr', 'hr123');
      MYSQL
      
      # STAP 6: Test data toevoegen (optioneel)
      echo "STAP 6: Test data toevoegen..."
      mysql -h $DB_HOST -u admin -p"$DB_PASS" -D innovatech <<MYSQL
      INSERT IGNORE INTO users (name, email, department, status, role) VALUES
      ('John Doe', 'john@innovatech.com', 'IT', 'Active', 'Manager'),
      ('Jane Smith', 'jane@innovatech.com', 'HR', 'Active', 'Accountant'),
      ('Bob Wilson', 'bob@innovatech.com', 'Facilities', 'Active', 'Cleaner');
      MYSQL
      
      echo "=== DATABASE SETUP VOLTOOID ==="
      echo "Database: innovatech"
      echo "Host: $DB_HOST"
      echo "Tabellen: users, hr"
      echo "Test gebruikers: admin/admin123, hr/hr123"
    EOT
  }
  
  depends_on = [
    aws_db_instance.db,
    aws_security_group.db_sg,
    aws_security_group.web_sg
  ]
}