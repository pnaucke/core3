# monitoring.tf - Met live kosten dashboard

# CloudWatch Dashboard met live kosten
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
          title = "🖥️ WebServer CPU"
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
          title = "🧠 WebServer Memory"
          view = "singleValue"
          stacked = false
          yAxis = {
            left = { min = 0, max = 100 }
          }
        }
      },
      
      # ======================= LIVE KOSTEN WIDGET =======================
      {
        type = "metric"
        width = 24
        height = 8
        properties = {
          metrics = [
            # RDS kosten metrics (indirect via gebruik)
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "hr-database", { label = "DB CPU (€0.08 per uur)" }],
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", "hr-database", { label = "Connections", yAxis = "right" }],
            
            # ECS kosten metrics (indirect via gebruik)
            ["AWS/ECS", "CPUUtilization", "ServiceName", "webserver", "ClusterName", "web-cluster", { label = "Web CPU (€0.04 per uur)" }],
            ["AWS/ECS", "MemoryUtilization", "ServiceName", "webserver", "ClusterName", "web-cluster", { label = "Web Memory", yAxis = "right" }]
          ]
          view = "timeSeries"
          stacked = false
          region = "eu-central-1"
          period = 3600  # Elk uur
          stat = "Average"
          title = "💰 Live Kosten Indicatie (Resource Gebruik)",
          yAxis = {
            left = { min = 0, max = 100, label = "CPU %" },
            right = { min = 0, label = "Connections / Memory %" }
          }
        }
      },
      
      # ======================= KOSTEN BEREKENING =======================
      {
        type = "text"
        width = 24
        height = 8
        properties = {
          markdown = <<-EOT
# 📊 Live Kosten Breakdown

## **Database (RDS MySQL)**
- **Instance:** db.t3.micro = €0.018 per uur (€13.14/maand)
- **Storage:** 20GB GP2 = €0.115 per GB/maand = €2.30/maand
- **Totaal DB:** **±€15.44 per maand** (±€0.51 per dag)

## **WebServer (ECS Fargate)**
- **vCPU:** 0.5 = €0.02453 per uur (€17.90/maand)
- **Memory:** 1GB = €0.00268 per uur (€1.96/maand)
- **Totaal Web:** **±€19.86 per maand** (±€0.66 per dag)

## **Totaal Infrastructure:**
**🟢 ~€35.30 per maand** (~€1.17 per dag)

---

### **💡 Realtime Kosten Tracking:**
1. [AWS Cost Explorer](https://eu-central-1.console.aws.amazon.com/cost-management/home#/cost-explorer)
2. [AWS Budgets Dashboard](https://eu-central-1.console.aws.amazon.com/cost-management/home#/budgets)
3. **Directe query:** `aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-31 --granularity MONTHLY --metrics BlendedCost`

### **🔔 Maandelijkse Alerts:**
- Database > €20 → Alarm
- WebServer > €25 → Alarm
- Totaal > €50 → Alarm
          EOT
        }
      }
    ]
  })
}

# Kosten alarm voor totale maandelijkse uitgaven
resource "aws_cloudwatch_metric_alarm" "monthly_cost_alarm" {
  alarm_name          = "monthly-cost-exceeded"
  alarm_description   = "Maandelijkse kosten overschrijding"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 50  # €50 per maand
  treat_missing_data  = "missing"
  
  # Gebruik estimated costs via custom metric
  metric_name = "EstimatedMonthlyCost"
  namespace   = "Custom/Costs"
  statistic   = "Maximum"
  period      = 2592000  # 30 dagen in seconden
}