
resource "aws_cloudwatch_dashboard" "main_dashboard" {
  dashboard_name = "Innovatech-Monitoring"
  
  dashboard_body = jsonencode({
    widgets = [
      # ======================= HEALTH & PERFORMANCE =======================
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", "webserver", "ClusterName", "web-cluster", { stat = "Average", label = "Web CPU" }]
          ]
          period = 60
          stat = "Average"
          region = "eu-central-1"
          title = "WebServer CPU"
          view = "singleValue"
          stacked = false
          yAxis = {
            left = { min = 0, max = 100 }
          }
        }
      },
      
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "MemoryUtilization", "ServiceName", "webserver", "ClusterName", "web-cluster", { stat = "Average", label = "Web Memory" }]
          ]
          period = 60
          stat = "Average"
          region = "eu-central-1"
          title = "WebServer Memory"
          view = "singleValue"
          stacked = false
          yAxis = {
            left = { min = 0, max = 100 }
          }
        }
      },
      
      # ======================= DATABASE PERFORMANCE =======================
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "hr-database", { label = "DB CPU" }]
          ]
          period = 60
          stat = "Average"
          region = "eu-central-1"
          title = "Database CPU"
          view = "singleValue"
          stacked = false
          yAxis = {
            left = { min = 0, max = 100 }
          }
        }
      },
      
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", "hr-database", { label = "DB Connections" }]
          ]
          period = 60
          stat = "Average"
          region = "eu-central-1"
          title = "Database Connections"
          view = "singleValue"
          stacked = false
          yAxis = {
            left = { min = 0 }
          }
        }
      },
      
      # ======================= LOAD BALANCER METRICS =======================
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "web-lb-innovatech", { stat = "Sum", label = "Requests" }]
          ]
          period = 60
          stat = "Sum"
          region = "eu-central-1"
          title = "Load Balancer Requests"
          view = "timeSeries"
          stacked = false
        }
      },
      
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "web-lb-innovatech", { stat = "Average", label = "Response Time" }]
          ]
          period = 60
          stat = "Average"
          region = "eu-central-1"
          title = "⏱Response Time"
          view = "timeSeries"
          stacked = false
          yAxis = {
            left = { min = 0, label = "Seconds" }
          }
        }
      }
    ]
  })
}

# Een SIMPELE WEKELIJKSE kosten alarm (werkt wel)
resource "aws_cloudwatch_metric_alarm" "weekly_high_usage" {
  alarm_name          = "weekly-high-usage-alert"
  alarm_description   = "Waarschuwt bij hoge wekelijkse resource usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 80  # 80% CPU usage
  treat_missing_data  = "missing"
  
  # Gebruik bestaande CPU metric (die wel werkt)
  metric_name = "CPUUtilization"
  namespace   = "AWS/ECS"
  statistic   = "Average"
  period      = 3600  # 1 uur (max 7 dagen voor alarms)
  
  dimensions = {
    ClusterName = "web-cluster"
    ServiceName = "webserver"
  }
}