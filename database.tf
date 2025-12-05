# Database setup - MET VEILIG HR WACHTWOORD
resource "null_resource" "setup_database" {
  triggers = {
    rds_instance_id  = aws_db_instance.db.id
    db_password_hash = sha256(var.db_password)
    hr_password_hash = sha256(var.hr_password)  # Alleen HR admin
    schema_version   = "1.0"
  }
  
  provisioner "local-exec" {
    command = <<EOT
      echo "=== DATABASE SETUP START ==="
      
      # Variabelen
      DB_HOST="${aws_db_instance.db.address}"
      DB_PASS="${var.db_password}"
      HR_PASS="${var.hr_password}"
      
      echo "Database host: $DB_HOST"
      
      # STAP 1: Wacht op RDS (max 2 minuten)
      echo "STAP 1: Wachten op RDS database..."
      max_attempts=12
      attempt=1
      
      until mysql -h "$DB_HOST" -u admin -p"$DB_PASS" -e "SELECT 1;" 2>/dev/null; do
        if [ $attempt -ge $max_attempts ]; then
          echo "ERROR: Database niet bereikbaar na $max_attempts pogingen"
          exit 1
        fi
        echo "Poging $attempt/$max_attempts..."
        sleep 10
        attempt=$((attempt+1))
      done
      
      # STAP 2: Database en tabellen maken
      echo "STAP 2: Database setup..."
      mysql -h "$DB_HOST" -u admin -p"$DB_PASS" <<SQL
-- Maak database als die niet bestaat
CREATE DATABASE IF NOT EXISTS innovatech;

USE innovatech;

-- Maak users tabel
CREATE TABLE IF NOT EXISTS users (
  id INT(5) AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50),
  email VARCHAR(50),
  department VARCHAR(50),
  status VARCHAR(50),
  role VARCHAR(50)
);

-- Maak hr tabel
CREATE TABLE IF NOT EXISTS hr (
  name VARCHAR(50) NOT NULL,
  password VARCHAR(50)
);

-- Voeg ALLEEN admin gebruiker toe met VEILIG wachtwoord uit GitHub
INSERT IGNORE INTO hr (name, password) VALUES 
('admin', '${HR_PASS}');
SQL
      
      echo "=== DATABASE SETUP COMPLEET ==="
      echo "HR admin gebruiker aangemaakt met wachtwoord uit GitHub Secret"
    EOT
  }
  
  depends_on = [
    aws_db_instance.db
  ]
}