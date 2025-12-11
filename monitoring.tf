# monitoring.tf - Clean dashboard zonder kosten informatie

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
      
      # ======================= BACKUP STATUS =======================
      {
        type = "log"
        width = 24
        height = 6
        properties = {
          region = "eu-central-1"
          title = "RDS Backup Status (Afgelopen 7 dagen)"
          query = "SOURCE '/aws/backup/rds-backup' | stats count(*) by bin(1d), @message\n| sort @timestamp desc\n| limit 7"
          view = "table"
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

# Alarm voor hoge CPU (> 80%)
resource "aws_cloudwatch_metric_alarm" "high_cpu_alarm" {
  alarm_name          = "high-cpu-alarm"
  alarm_description   = "Waarschuwt bij CPU gebruik boven 80%"
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
  
  alarm_actions = []
  ok_actions    = []
}

# Alarm voor gefaalde database backup
resource "aws_cloudwatch_metric_alarm" "failed_backup_alarm" {
  alarm_name          = "failed-backup-alarm"
  alarm_description   = "Waarschuwt bij gefaalde database backup"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 0
  period              = 300
  
  metric_name = "BackupJobSuccess"
  namespace   = "AWS/Backup"
  statistic   = "Sum"
  
  dimensions = {
    BackupVaultName = "rds-daily-backup-vault"
  }
  
  alarm_actions = []
  ok_actions    = []
}