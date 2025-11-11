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
}

# Uptime Alarm via ALB Target Group
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
    TargetGroup  = aws_lb_target_group.web_tg.arn_suffix
    LoadBalancer = aws_lb.web_lb.arn_suffix
  }
}

# ----------------------
# CloudWatch Dashboard
# ----------------------
resource "aws_cloudwatch_dashboard" "web_dashboard" {
  dashboard_name = "web-servers-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # CPU Usage grafiek
      {
        type = "metric"
        x = 0
        y = 0
        width = 24
        height = 6
        properties = {
          view = "timeSeries"
          title = "CPU Usage Webservers"
          region = "eu-central-1"
          stacked = false
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.web1.id, { "stat": "Average", "color": "#1f77b4", "label": "Webserver1" }],
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.web2.id, { "stat": "Average", "color": "#ff7f0e", "label": "Webserver2" }]
          ]
          yAxis = { left = { min = 0, max = 100 } }
          period = 60
        }
      },

      # Uptime Webserver1 (Up/Down)
      {
        type = "metric"
        x = 0
        y = 7
        width = 12
        height = 6
        properties = {
          view = "singleValue"
          title = "Webserver1 Uptime"
          region = "eu-central-1"
          metrics = [
            [ "AWS/ApplicationELB", "UnhealthyHostCount", "TargetGroup", aws_lb_target_group.web_tg.arn_suffix, "LoadBalancer", aws_lb.web_lb.arn_suffix, { "id": "m1" } ],
            [ { "expression": "IF(m1==0,1,0)", "label": "UpFlag", "color": "#2ca02c" } ]
          ]
          period = 60
          stat = "Maximum"
          annotations = {}
        }
      },

      # Uptime Webserver2 (Up/Down)
      {
        type = "metric"
        x = 12
        y = 7
        width = 12
        height = 6
        properties = {
          view = "singleValue"
          title = "Webserver2 Uptime"
          region = "eu-central-1"
          metrics = [
            [ "AWS/ApplicationELB", "UnhealthyHostCount", "TargetGroup", aws_lb_target_group.web_tg.arn_suffix, "LoadBalancer", aws_lb.web_lb.arn_suffix, { "id": "m2" } ],
            [ { "expression": "IF(m2==0,1,0)", "label": "UpFlag", "color": "#2ca02c" } ]
          ]
          period = 60
          stat = "Maximum"
          annotations = {}
        }
      }
    ]
  })
}
