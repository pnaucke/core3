# Security group voor database
resource "aws_security_group" "sg_database" {
  name        = "database-sg"
  description = "Security group for database"
  vpc_id      = aws_vpc.hr.id

  # MySQL toegang alleen van specifieke IPs
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["82.170.150.87/32", "145.93.76.108/32"]
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