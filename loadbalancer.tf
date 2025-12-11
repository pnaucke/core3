# Application Load Balancer
resource "aws_lb" "web_lb" {
  name               = "web-lb-innovatech"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_loadbalancer.id]
  subnets            = [aws_subnet.subnet_lb1.id, aws_subnet.subnet_lb2.id]

  enable_deletion_protection = false

  tags = {
    Name = "web-lb-innovatech"
  }
}

# Target Group
resource "aws_lb_target_group" "webserver" {
  name        = "webserver-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.hr.id
  target_type = "ip"

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "webserver-tg"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webserver.arn
  }
}