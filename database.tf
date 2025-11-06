resource "aws_db_subnet_group" "hr_db_subnets" {
  name       = "hr-db-subnet-group"
  subnet_ids = [aws_subnet.db_private.id]

  tags = { Name = "hr-db-subnet-group" }
}

resource "aws_db_instance" "hr_db" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "15.3"
  instance_class       = "db.t3.micro"
  # name = "hr_db" # gebruik alleen als compatible
  username             = "hradmin"
  password             = "ChangeMe123!" 
  parameter_group_name = "default.postgres15"
  skip_final_snapshot  = true
  publicly_accessible  = false
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.hr_db_subnets.name
}
