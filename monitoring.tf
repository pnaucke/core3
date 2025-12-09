# CloudWatch Dashboard for ECS monitoring
resource "aws_cloudwatch_dashboard" "webserver_dashboard" {
  dashboard_name = "WebServer-Monitoring"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric",
        width = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", "webserver", "ClusterName", "web-cluster", { stat = "Average", label = "CPU %" }]
          ],
          period = 60,
          stat = "Average",
          region = "eu-central-1",
          title = "CPU Utilization",
          view = "singleValue",
          stacked = false,
          setPeriodToTimeRange = false,
          yAxis = {
            left = {
              min = 0,
              max = 100,
              showUnits = false
            }
          }
        }
      },
      {
        type = "metric",
        width = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/ECS", "MemoryUtilization", "ServiceName", "webserver", "ClusterName", "web-cluster", { stat = "Average", label = "Memory %" }]
          ],
          period = 60,
          stat = "Average",
          region = "eu-central-1",
          title = "Memory Utilization",
          view = "singleValue",
          stacked = false,
          setPeriodToTimeRange = false,
          yAxis = {
            left = {
              min = 0,
              max = 100,
              showUnits = false
            }
          }
        }
      },
      {
        type = "metric",
        width = 24,
        height = 8,
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", "webserver", "ClusterName", "web-cluster", { stat = "Average", label = "CPU Utilization" }]
          ],
          view = "timeSeries",
          stacked = false,
          region = "eu-central-1",
          period = 60,
          stat = "Average",
          title = "CPU Utilization Over Time (0-100%)",
          yAxis = {
            left = {
              min = 0,
              max = 100,
              showUnits = false
            }
          }
        }
      }
    ]
  })
}

# CloudWatch Alarm for high CPU utilization
resource "aws_cloudwatch_metric_alarm" "cpu_high_web" {
  alarm_name          = "cpu-high-webserver"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alarm when WebServer CPU exceeds 80%"
  treat_missing_data  = "missing"
  
  dimensions = {
    ClusterName = "web-cluster"
    ServiceName = "webserver"
  }

  tags = {
    Name        = "cpu-high-webserver"
    Environment = "Production"
    Resource    = "Webserver"
  }
}