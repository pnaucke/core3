# Database security group
resource "aws_security_group" "sg_database" {
  name        = "database-sg"
  description = "Security group for database"
  vpc_id      = aws_vpc.hr.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["172.31.1.0/24"]
  }

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

# Webserver security group
resource "aws_security_group" "sg_webserver" {
  name        = "webserver-sg"
  description = "Security group for webserver"
  vpc_id      = aws_vpc.hr.id

ingress {
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  security_groups = [aws_security_group.sg_loadbalancer.id]
}

ingress {
  from_port       = 443
  to_port         = 443
  protocol        = "tcp"
  security_groups = [aws_security_group.sg_loadbalancer.id]
}

  tags = {
    Name = "sg_webserver"
  }
}

# Load balancer security group
resource "aws_security_group" "sg_loadbalancer" {
  name        = "loadbalancer-sg"
  description = "Security group for load balancer"
  vpc_id      = aws_vpc.hr.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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