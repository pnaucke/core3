# ----------------------
# Monitoring via CloudWatch
# ----------------------

# ----------------------
# CPU Alarms
# ----------------------
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

  alarm_description = "Alarm wanneer CPU van Web1 boven 80% komt"
}

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

  alarm_description = "Alarm wanneer CPU van Web2 boven 80% komt"
}

# ----------------------
# Uptime Alarm via Target Group Health
# ----------------------
resource "aws_cloudwatch_metric_alarm" "uptime_webservers" {
  alarm_name          = "uptime-webservers"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnhealthyHostCount"
  namespace           = "AWS/ELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0

  dimensions = {
    TargetGroup = aws_lb_target_group.web_tg.arn_suffix
    LoadBalancer = aws_lb.web_lb.arn_suffix
  }

  alarm_description = "Alarm wanneer één of meerdere webservers down zijn"
}

# ----------------------
# CloudWatch Dashboard
# ----------------------
resource "aws_cloudwatch_dashboard" "web_dashboard" {
  dashboard_name = "web-dashboard"
  dashboard_body = jsonencode({
    widgets = [
      # Paneel 1: CPU Usage Webservers
      {
        type  = "metric"
        x     = 0
        y     = 0
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.web1.id, { "stat": "Average", "label": "Webserver1 CPU", "color": "#1f77b4" }],
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.web2.id, { "stat": "Average", "label": "Webserver2 CPU", "color": "#ff7f0e" }]
          ]
          view       = "timeSeries"
          stacked    = false
          region     = "eu-central-1"
          title      = "CPU Usage Webservers"
          yAxis     = {
            left = { min = 0, max = 100, label = "CPU %" }
          }
        }
      },
      # Paneel 2: Uptime Webservers
      {
        type  = "metric"
        x     = 0
        y     = 7
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "StatusCheckFailed_Instance", "InstanceId", aws_instance.web1.id, { "stat": "Maximum", "label": "Webserver1" }],
            ["AWS/EC2", "StatusCheckFailed_Instance", "InstanceId", aws_instance.web2.id, { "stat": "Maximum", "label": "Webserver2" }]
          ]
          view    = "singleValue"
          region  = "eu-central-1"
          title   = "Uptime Webservers (0=Up,1=Down)"
        }
      }
    ]
  })
}
