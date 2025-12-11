# monitoring.tf - Dashboard met werkende database status monitoring

# CloudWatch Dashboard
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
      
      # ======================= DATABASE UPTIME =======================
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "hr-database", { stat = "Average", label = "Database CPU" }]
          ]
          period = 60
          stat = "Average"
          region = "eu-central-1"
          title = "Database Status (CPU = Uptime)"
          view = "singleValue"
          stacked = false
          yAxis = {
            left = { min = 0, max = 100 }
          }
        }
      },
      
      # ======================= MAANDELIJKSE KOSTEN =======================
      {
        type = "text"
        width = 12
        height = 6
        properties = {
          markdown = "## Database Kosten per Maand\n\n- RDS Instance: db.t3.micro = €13.14\n- Storage: 20GB GP2 = €2.30\n- Totaal: €15.44 per maand"
        }
      },
      
      {
        type = "text"
        width = 12
        height = 6
        properties = {
          markdown = "## WebCluster Kosten per Maand\n\n- vCPU: 0.5 = €17.90\n- Memory: 1GB = €1.96\n- Totaal: €19.86 per maand"
        }
      }
    ]
  })
}

# SNS topic voor alarms
resource "aws_sns_topic" "alarms" {
  name = "innovatech-alarms"
}

# SNS email subscription
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = "554603@student.fontys.nl"
}

# Alarm voor hoge website CPU (> 80%)
resource "aws_cloudwatch_metric_alarm" "high_cpu_alarm" {
  alarm_name          = "high-cpu-alarm"
  alarm_description   = "Website CPU boven 80%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 80
  period              = 300
  
  metric_name = "CPUUtilization"
  namespace   = "AWS/ECS"
  statistic   = "Average"
  
  dimensions = {
    ClusterName = "web-cluster"
    ServiceName = "webserver"
  }
  
  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
}

# Alarm voor database downtime
resource "aws_cloudwatch_metric_alarm" "database_downtime_alarm" {
  alarm_name          = "database-downtime-alarm"
  alarm_description   = "Database is down (geen CPU metrics)"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  threshold           = 0.01
  period              = 60
  
  metric_name = "CPUUtilization"
  namespace   = "AWS/RDS"
  statistic   = "Average"
  
  dimensions = {
    DBInstanceIdentifier = "hr-database"
  }
  
  treat_missing_data = "breaching"
  
  # Belangrijk: Lambda + SNS samen
  alarm_actions = [
    aws_sns_topic.alarms.arn,
    aws_lambda_function.db_restarter.arn
  ]
  ok_actions    = [aws_sns_topic.alarms.arn]
}