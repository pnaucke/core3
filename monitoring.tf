resource "aws_cloudwatch_metric_alarm" "cpu_high_task" {
  alarm_name          = "cpu-high-task"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    ClusterName = aws_ecs_cluster.hr_cluster.name
    ServiceName = aws_ecs_service.hr_service.name
  }

  alarm_description = "Alarm wanneer CPU van ECS Fargate task boven 80% komt"
}

resource "aws_cloudwatch_dashboard" "hr_dashboard" {
  dashboard_name = "hr-dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type  = "metric"
        x     = 0
        y     = 0
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.hr_cluster.name, "ServiceName", aws_ecs_service.hr_service.name, { "stat": "Average", "label": "HR Task CPU" }]
          ]
          view       = "timeSeries"
          stacked    = false
          region     = "eu-central-1"
          title      = "CPU Usage ECS Fargate Task"
          yAxis     = { left = { min = 0, max = 100, label = "CPU %" } }
        }
      }
    ]
  })
}
