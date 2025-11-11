# ----------------------
# CloudWatch Alarms voor Webservers
# ----------------------
resource "aws_cloudwatch_metric_alarm" "cpu_high_web1" {
  alarm_name          = "cpu_high_web1"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alarm bij CPU > 80% op Webserver1"
  dimensions = {
    InstanceId = aws_instance.webserver1.id
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_high_web2" {
  alarm_name          = "cpu_high_web2"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alarm bij CPU > 80% op Webserver2"
  dimensions = {
    InstanceId = aws_instance.webserver2.id
  }
}

resource "aws_cloudwatch_metric_alarm" "uptime_webserver" {
  alarm_name          = "uptime_webserver"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnhealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "Alarm bij ongezonde host in ALB target group"
  dimensions = {
    TargetGroup   = aws_lb_target_group.web_tg.arn_suffix
    LoadBalancer  = aws_lb.web_lb.arn_suffix
  }
}

# ----------------------
# CloudWatch Dashboard met kleuren voor uptime
# ----------------------
resource "aws_cloudwatch_dashboard" "web_dashboard" {
  dashboard_name = "webservers-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.webserver1.id, { "stat": "Average", "color": "#1f77b4" }],
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.webserver2.id, { "stat": "Average", "color": "#ff7f0e" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "eu-central-1"
          title   = "CPU Usage Webservers"
          period  = 60
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "UnhealthyHostCount", "TargetGroup", aws_lb_target_group.web_tg.arn_suffix, "LoadBalancer", aws_lb.web_lb.arn_suffix, { "stat": "Average", "color": "#d62728" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "eu-central-1"
          title   = "Webserver Uptime (0 = healthy, 1 = unhealthy)"
          period  = 60
          yAxis = {
            left = {
              min = 0
              max = 1
            }
          }
        }
      }
    ]
  })
}
