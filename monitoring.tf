# monitoring.tf - Gecombineerd dashboard voor Health, Performance & Cost

resource "aws_cloudwatch_dashboard" "main_dashboard" {
  dashboard_name = "Innovatech-Dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      # ======================= HEALTH & PERFORMANCE =======================
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
          title = "🖥️ WebServer CPU",
          view = "singleValue",
          stacked = false,
          setPeriodToTimeRange = false,
          yAxis = {
            left = { min = 0, max = 100, showUnits = false }
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
          title = "🧠 WebServer Memory",
          view = "singleValue",
          stacked = false,
          setPeriodToTimeRange = false,
          yAxis = {
            left = { min = 0, max = 100, showUnits = false }
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
          title = "📈 CPU Utilization Over Time (0-100%)",
          yAxis = {
            left = { min = 0, max = 100, showUnits = false }
          }
        }
      },
      
      # ======================= COST MANAGEMENT =======================
      {
        type = "text",
        width = 24,
        height = 2,
        properties = {
          markdown = "# 💰 Cost Management Dashboard\nREQ-NCA-P3-12/13/14: Health, Performance & Cost Monitoring"
        }
      },
      
      {
        type = "metric",
        width = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "hr-database", { "label": "Database CPU %" }],
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", "hr-database", { "label": "Free Storage (MB)", "yAxis": "right" }],
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", "hr-database", { "label": "Active Connections", "yAxis": "right" }]
          ],
          view = "timeSeries",
          stacked = false,
          region = "eu-central-1",
          stat = "Average",
          period = 300,
          title = "📊 Database Usage (Impacts Cost)",
          yAxis = {
            left = { min = 0, max = 100, label = "CPU %" },
            right = { label = "MB / Connections" }
          }
        }
      },
      
      {
        type = "metric",
        width = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/RDS", "NetworkTransmitThroughput", "DBInstanceIdentifier", "hr-database", { "label": "DB Out (KB/s)" }],
            ["AWS/RDS", "NetworkReceiveThroughput", "DBInstanceIdentifier", "hr-database", { "label": "DB In (KB/s)", "yAxis": "right" }]
          ],
          view = "timeSeries",
          stacked = false,
          region = "eu-central-1",
          stat = "Average",
          period = 300,
          title = "📡 Data Transfer (Network Costs)",
          yAxis = {
            left = { label = "Out KB/s" },
            right = { label = "In KB/s" }
          }
        }
      },
      
      {
        type = "metric",
        width = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "web-lb-innovatech", { "label": "Requests/min", "stat": "Sum", "period": 60 }]
          ],
          view = "timeSeries",
          stacked = false,
          region = "eu-central-1",
          stat = "Sum",
          period = 60,
          title = "⚡ Load Balancer Requests"
        }
      },
      
      {
        type = "text",
        width = 12,
        height = 6,
        properties = {
          markdown = "## 💡 Cost Optimization Tips\n\n**Storage:**\n- Monitor FreeStorageSpace\n- Clean old logs regularly\n\n**Database:**\n- Keep CPU < 70%\n- Limit connections\n\n**Network:**\n- Reduce data transfer\n- Use compression"
        }
      },
      
      {
        type = "text",
        width = 24,
        height = 4,
        properties = {
          markdown = "## 🔗 AWS Cost Tools\n\n- **AWS Cost Explorer**: Detailed cost analysis\n- **AWS Budgets**: Set cost alerts\n- **Cost Allocation Tags**: Use tags: `Environment=production`, `ManagedBy=Terraform`\n- **Trusted Advisor**: Cost optimization checks"
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