# ----------------------
# CloudWatch Monitoring
# ----------------------

# CPU Alarm Web1
resource "aws_cloudwatch_metric_alarm" "cpu_high_web1" {
  alarm_name          = "cpu-high-web1"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    InstanceId = aws_instance.web1.id
  }

  alarm_description = "Alarm als CPU van Webserver1 > 80% voor 1 minuut"
}

# CPU Alarm Web2
resource "aws_cloudwatch_metric_alarm" "cpu_high_web2" {
  alarm_name          = "cpu-high-web2"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    InstanceId = aws_instance.web2.id
  }

  alarm_description = "Alarm als CPU van Webserver2 > 80% voor 1 minuut"
}

# Uptime Alarm via ALB Target Group (gezamenlijk)
resource "aws_cloudwatch_metric_alarm" "uptime_webserver" {
  alarm_name          = "uptime-webserver"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnhealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0

  dimensions = {
    TargetGroup = aws_lb_target_group.web_tg.arn_suffix
    LoadBalancer = aws_lb.web_lb.arn_suffix
  }

  alarm_description = "Alarm als een van de webservers in ALB ongezond is"
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "web_dashboard" {
  dashboard_name = "web-servers-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        x = 0
        y = 0
        width = 12
        height = 6
        properties = {
          view = "timeSeries"
          title = "CPU Usage Webservers"
          region = "eu-central-1"
          stacked = false
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.web1.id, { "stat": "Average", "color": "#1f77b4" }],
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.web2.id, { "stat": "Average", "color": "#ff7f0e" }]
          ]
          period = 60
        }
      },
      {
        type = "metric"
        x = 0
        y = 7
        width = 12
        height = 6
        properties = {
          view = "singleValue"
          title = "Webservers Uptime"
          region = "eu-central-1"
          metrics = [
            ["AWS/ApplicationELB", "UnhealthyHostCount", "TargetGroup", aws_lb_target_group.web_tg.arn_suffix, "LoadBalancer", aws_lb.web_lb.arn_suffix, { "label": "Webservers", "color": "#2ca02c" }]
          ]
          period = 60
        }
      }
    ]
  })
}
