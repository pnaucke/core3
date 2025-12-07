# Security group voor database
resource "aws_security_group" "sg_database" {
  name        = "database-sg"
  description = "Security group for database"
  vpc_id      = aws_vpc.hr.id

  # MySQL toegang alleen van specifieke IPs en webserver
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["82.170.150.87/32", "145.93.76.108/32"]
  }

  # MySQL toegang van webserver security group
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_webserver.id]
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

# Security group voor webserver
resource "aws_security_group" "sg_webserver" {
  name        = "webserver-sg"
  description = "Security group for webserver"
  vpc_id      = aws_vpc.hr.id

  # HTTP toegang alleen van load balancer
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_loadbalancer.id]
  }

  # HTTPS toegang alleen van load balancer
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_loadbalancer.id]
  }

  # Uitgaand verkeer
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg_webserver"
  }
}

# Security group voor load balancer
resource "aws_security_group" "sg_loadbalancer" {
  name        = "loadbalancer-sg"
  description = "Security group for load balancer"
  vpc_id      = aws_vpc.hr.id

  # HTTP van overal
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS van overal
  ingress {
    from_port   = 443
    to_port     = 443
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
    Name = "sg_loadbalancer"
  }
}