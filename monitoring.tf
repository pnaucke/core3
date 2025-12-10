# monitoring.tf - Vereenvoudigd dashboard

# CloudWatch Dashboard voor monitoring
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
      
      # ======================= WEEKLY COST ESTIMATES =======================
      {
        type = "text"
        width = 24
        height = 4
        properties = {
          markdown = "# 💰 Wekelijkse Kosten Schatting\n\n**Database (RDS):** ~€2.50/week\n- db.t3.micro instance\n- 20 GB GP2 storage\n\n**WebServer (ECS):** ~€3.50/week\n- 0.5 vCPU Fargate\n- 1 GB memory\n\n**Totaal:** ~€6.00/week\n\n*Schatting gebaseerd on AWS prijzen EU-centraal-1*"
        }
      },
      
      # ======================= COST LINKS =======================
      {
        type = "text"
        width = 24
        height = 3
        properties = {
          markdown = "## 🔗 Cost Management Tools\n- [AWS Cost Explorer](https://eu-central-1.console.aws.amazon.com/cost-management/home#/cost-explorer)\n- [AWS Budgets](https://eu-central-1.console.aws.amazon.com/cost-management/home#/budgets)\n- [Cost & Usage Reports](https://eu-central-1.console.aws.amazon.com/cost-management/home#/reports)"
        }
      }
    ]
  })
}