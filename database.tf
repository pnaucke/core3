# DB Subnet Group
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = [aws_subnet.subnet_db_private.id] # pas aan naar jouw subnet
}

# RDS Database
resource "aws_db_instance" "db" {
  identifier              = "hrdb-${random_id.suffix.hex}"
  allocated_storage       = 20
  engine                  = "postgres"
  engine_version          = "15.3"
  instance_class          = "db.t3.micro"
  db_name                 = "myappdb"
  username                = "hradmin"
  password                = terraform.workspace == "default" ? "" : (lookup(env, "DB_PASSWORD", "")) 
  parameter_group_name    = "default.postgres15"
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.db_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.db_subnet_group.name
  publicly_accessible     = false
  port                    = 5432
}

