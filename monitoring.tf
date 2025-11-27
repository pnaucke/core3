# CloudWatch CPU alarm
resource "aws_cloudwatch_metric_alarm" "cpu_high_web" {
  alarm_name          = "cpu_high_web"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 80
  period              = 60
  statistic           = "Average"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"

  dimensions = {
    ClusterName = aws_ecs_cluster.webcluster.name
    ServiceName = aws_ecs_service.webservice.name
  }

  alarm_description = "CPU boven 80 procent"
}

# CloudWatch dashboard
resource "aws_cloudwatch_dashboard" "ecs_cpu_dashboard" {
  dashboard_name = "ecs_cpu_dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          region  = var.aws_region
          title   = "ECS CPU gebruik"
          metrics = [
            [
              "AWS/ECS",
              "CPUUtilization",
              "ClusterName",
              aws_ecs_cluster.webcluster.name,
              "ServiceName",
              aws_ecs_service.webservice.name
            ]
          ]
          view    = "timeSeries"
          stacked = false
          period  = 60
          stat    = "Average"
          annotations = {
            alarms = [
              aws_cloudwatch_metric_alarm.cpu_high_web.arn
            ]
          }
        }
      }
    ]
  })
}
