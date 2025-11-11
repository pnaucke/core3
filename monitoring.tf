# ----------------------
# CloudWatch Alarms voor EC2 Webservers
# ----------------------

# CPU alarm Webserver1
resource "aws_cloudwatch_metric_alarm" "cpu_high_web1" {
  alarm_name          = "cpu-high-web1"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alarm wanneer CPU > 80% over 1 minuut"
  dimensions = {
    InstanceId = aws_instance.web1.id
  }
}

# CPU alarm Webserver2
resource "aws_cloudwatch_metric_alarm" "cpu_high_web2" {
  alarm_name          = "cpu-high-web2"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alarm wanneer CPU > 80% over 1 minuut"
  dimensions = {
    InstanceId = aws_instance.web2.id
  }
}

# ----------------------
# CloudWatch Alarm voor ALB Target Group (Uptime)
# ----------------------
resource "aws_cloudwatch_metric_alarm" "uptime_webserver" {
  alarm_name          = "uptime-webserver"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnhealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alarm wanneer ALB target group een ongezonde host detecteert"
  dimensions = {
    TargetGroup = aws_lb_target_group.web_tg.arn_suffix
    LoadBalancer = aws_lb.web_lb.arn_suffix
  }
}
