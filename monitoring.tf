# monitoring.tf - Dashboard zonder backup, met database beschikbaarheid

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
      
      # ======================= DATABASE STATUS (UP/DOWN) =======================
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", "hr-database", { 
              stat = "Average", 
              label = "Database Status",
              # Deze expressie zet verbindingen om naar 1=Up, 0=Down voor display
              expression = "IF(m1>0,1,0)", 
              id = "e1",
              visible = false
            }],
            [{"expression": "IF(m1>0,1,0)", "label": "Up", "id": "e1", "period": 60}]
          ]
          period = 60
          stat = "Average"
          region = "eu-central-1"
          title = "Database Status (Up/Down)"
          view = "singleValue"
          stacked = false
          yAxis = {
            left = { min = 0, max = 1 }
          }
          annotations = {
            horizontal = [
              {
                color = "#2ca02c",
                label = "Up",
                value = 1
              },
              {
                color = "#d62728", 
                label = "Down",
                value = 0
              }
            ]
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

# Alarm voor database offline (1 minuut geen verbindingen)
resource "aws_cloudwatch_metric_alarm" "database_down" {
  alarm_name          = "database-down-alarm"
  alarm_description   = "Waarschuwt als de database 1 minuut offline is (0 verbindingen)"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  threshold           = 1  # Minder dan 1 verbinding gedurende 1 minuut = offline
  period              = 60 # 1 minuut
  
  metric_name = "DatabaseConnections"
  namespace   = "AWS/RDS"
  statistic   = "Average"
  
  dimensions = {
    DBInstanceIdentifier = "hr-database"
  }
  
  alarm_actions = []  # Vul hier later een SNS Topic ARN in voor meldingen
  ok_actions    = []
}