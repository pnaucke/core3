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
      
  # ======================= BACKUP STATUS (AFGELOPEN 7 DAGEN) =======================
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          metrics = [ ["Backup", "SuccessfulBackupCount", { "label": "Geslaagd" }] ]
          view    = "timeSeries"
          stacked = false
          region  = "eu-central-1"
          title   = "Geslaagde Backups (7 dagen)"
          stat    = "Sum"
          period  = 86400 # Data gegroepeerd per dag
          start   = "-P7D" # Startpunt: 7 dagen geleden
        }
      },
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          metrics = [ ["Backup", "FailedBackupCount", { "label": "Mislukt" }] ]
          view    = "timeSeries"
          stacked = false
          region  = "eu-central-1"
          title   = "Mislukte Backups (7 dagen)"
          stat    = "Sum"
          period  = 86400
          start   = "-P7D"
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