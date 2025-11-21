resource "aws_lb" "web_lb" {
  name               = "weblb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [
    aws_subnet.lb_subnet1.id,
    aws_subnet.lb_subnet2.id
  ]

  enable_deletion_protection = false

  tags = {
    Name = "weblb"
  }
}

resource "aws_lb_target_group" "web_tg" {
  name        = "webtg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    protocol = "HTTP"
    path     = "/"
    interval = 15
  }

  tags = {
    Name = "webtg"
  }
}

resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}
