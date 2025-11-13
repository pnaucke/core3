# ----------------------
# database.tf
# ----------------------

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = [aws_subnet.db_subnet.id]
  tags = { Name = "db-subnet-group" }
}

resource "aws_db_instance" "db" {
  identifier              = "hr-db"
  allocated_storage       = 20
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  db_name                 = "hrdatabase"
  username                = "admin"
  password                = var.db_password
  parameter_group_name    = "default.mysql8.0"
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.db_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.db_subnet_group.name
  publicly_accessible     = false
  tags = { Name = "HR Database" }

  # Provisioning SQL after creation
  lifecycle {
    ignore_changes = [username, password]
  }
}

# ----------------------
# Optional: Provision the employees table
# ----------------------
resource "null_resource" "init_db" {
  depends_on = [aws_db_instance.db]

  provisioner "local-exec" {
    command = <<EOT
mysql -h ${aws_db_instance.db.address} -uadmin -p${var.db_password} -e "
CREATE TABLE IF NOT EXISTS employees (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50),
    department VARCHAR(50),
    status VARCHAR(50),
    role VARCHAR(50)
);"
EOT
    interpreter = ["/bin/bash", "-c"]
  }
}
