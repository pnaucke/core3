# ----------------------
# CPU Alarms per Webserver
# ----------------------
resource "aws_cloudwatch_metric_alarm" "cpu_high_web1" {
  alarm_name          = "cpu-high-webserver1"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "CPU utilization hoger dan 80% voor Webserver1"
  alarm_actions       = [] # optioneel
  dimensions = {
    InstanceId = aws_instance.webserver1.id
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_high_web2" {
  alarm_name          = "cpu-high-webserver2"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "CPU utilization hoger dan 80% voor Webserver2"
  alarm_actions       = [] # optioneel
  dimensions = {
    InstanceId = aws_instance.webserver2.id
  }
}

# ----------------------
# CloudWatch Dashboard
# ----------------------
resource "aws_cloudwatch_dashboard" "web_dashboard" {
  dashboard_name = "web-servers-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # Paneel 1: CPU grafiek voor beide webservers
      {
        type = "metric"
        x = 0
        y = 0
        width = 12
        height = 6
        properties = {
          view = "timeSeries"
          stacked = false
          region = "eu-central-1"
          title = "CPU Usage Webservers"
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.webserver1.id, { "stat": "Average", "label": "Webserver1 CPU", "color": "#1f77b4" }],
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.webserver2.id, { "stat": "Average", "label": "Webserver2 CPU", "color": "#ff7f0e" }]
          ]
          period = 60
          yAxis = {
            left = {
              min = 0
              max = 100
              label = "CPU %"
            }
          }
        }
      },

      # Paneel 2: Uptime Webserver1
      {
        type = "metric"
        x = 0
        y = 7
        width = 6
        height = 3
        properties = {
          view = "singleValue"
          region = "eu-central-1"
          title = "Webserver1 Uptime"
          metrics = [
            ["AWS/EC2", "StatusCheckFailed_Instance", "InstanceId", aws_instance.webserver1.id, { "stat": "Maximum", "label": "Webserver1" }]
          ]
          period = 60
          annotations = {}
          setPeriodToTimeRange = true
          sparkline = false
        }
      },

      # Paneel 3: Uptime Webserver2
      {
        type = "metric"
        x = 6
        y = 7
        width = 6
        height = 3
        properties = {
          view = "singleValue"
          region = "eu-central-1"
          title = "Webserver2 Uptime"
          metrics = [
            ["AWS/EC2", "StatusCheckFailed_Instance", "InstanceId", aws_instance.webserver2.id, { "stat": "Maximum", "label": "Webserver2" }]
          ]
          period = 60
          annotations = {}
          setPeriodToTimeRange = true
          sparkline = false
        }
      }
    ]
  })
}
