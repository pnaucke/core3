# CloudWatch Dashboard for ECS monitoring
resource "aws_cloudwatch_dashboard" "webserver_dashboard" {
  dashboard_name = "WebServer-Monitoring"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric",
        width = 24,
        height = 6,
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", "webserver", "ClusterName", "web-cluster", { stat = "Average" }]
          ],
          period = 60,
          stat = "Average",
          region = "eu-central-1",
          title = "WebServer CPU Utilization (%)",
          view = "singleValue",
          stacked = false,
          setPeriodToTimeRange = false,
          yAxis = {
            left = {
              min = 0,
              max = 100,
              showUnits = false,
              label = "Percentage"
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
            ["AWS/ECS", "CPUUtilization", "ServiceName", "webserver", "ClusterName", "web-cluster", { stat = "Average", period = 60, label = "CPU %" }]
          ],
          view = "timeSeries",
          stacked = false,
          region = "eu-central-1",
          period = 60,
          stat = "Average",
          title = "WebServer CPU Utilization Over Time",
          yAxis = {
            left = {
              min = 0,
              max = 100,
              label = "Percentage",
              showUnits = false
            }
          }
        }
      },
      {
        type = "text",
        width = 24,
        height = 2,
        properties = {
          markdown = "# 📊 ECS WebServer Monitoring\n\n## Real-time CPU Utilization Metrics"
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
          view = "gauge",
          stacked = false,
          region = "eu-central-1",
          period = 60,
          stat = "Average",
          title = "Memory Utilization",
          yAxis = {
            left = {
              min = 0,
              max = 100
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
            [".", "RunningTaskCount", ".", ".", ".", ".", { stat = "Maximum", label = "Running Tasks" }]
          ],
          view = "singleValue",
          stacked = false,
          region = "eu-central-1",
          period = 60,
          stat = "Maximum",
          title = "Running Tasks",
          annotations = {
            horizontal = [
              {
                color = "#2ca02c",
                label = "Healthy",
                value = 1
              }
            ]
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