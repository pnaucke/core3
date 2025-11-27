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
  dashboard_name = "Dashboard"

  dashboard_body = jsonencode({
    start = "-PT24H"
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
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
          region  = "eu-central-1"
          stat    = "Average"
          period  = 60
        }
      }
    ]
  })
}
