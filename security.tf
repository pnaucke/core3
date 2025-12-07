# Security group voor database (extern toegankelijk)
resource "aws_security_group" "sg_database" {
  name        = "database-sg"  # <- ANDERE NAAM, geen "sg-" prefix
  description = "Security group for database"
  vpc_id      = aws_vpc.hr.id

  # MySQL toegang van buitenaf (vanaf elk IP)
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Uitgaand verkeer
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg_database"
  }
}