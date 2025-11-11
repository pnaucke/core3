# ----------------------
# Application Load Balancer
# ----------------------
resource "aws_lb" "web_lb" {
  name               = "web-lb-${random_id.suffix.hex}"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.web1_subnet.id, aws_subnet.web2_subnet.id]
  security_groups    = [aws_security_group.web_sg.id]
  tags = { Name = "Loadbalancer" }
}

# ----------------------
# Target Group voor Webservers
# ----------------------
resource "aws_lb_target_group" "web_tg" {
  name        = "web-tg-${random_id.suffix.hex}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main_vpc.id
  target_type = "instance"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = { Name = "web-tg" }
}

# ----------------------
# Listener Load Balancer
# ----------------------
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# ----------------------
# Target Group Attachments
# ----------------------
resource "aws_lb_target_group_attachment" "web1_attach" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "web2_attach" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web2.id
  port             = 80
}
