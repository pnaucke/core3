resource "aws_cloudwatch_metric_alarm" "cpu_high_web" {
  alarm_name          = "cpu_high_web"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    ClusterName = aws_ecs_cluster.webcluster.name
    ServiceName = aws_ecs_service.webservice.name
  }

  alarm_actions = []
}

resource "aws_cloudwatch_log_metric_filter" "ssh_unauthorized_filter" {
  name           = "ssh_unauthorized_filter"
  pattern        = "{ $.eventName = \"AuthorizeSecurityGroupIngress\" }"
  log_group_name = "/aws/vpc/flowlogs"

  metric_transformation {
    name      = "ssh_unauthorized_count"
    namespace = "CustomSecurity"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "ssh_unauthorized_alarm" {
  alarm_name          = "ssh_unauthorized_alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ssh_unauthorized_count"
  namespace           = "CustomSecurity"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_actions       = []
}

resource "aws_cloudwatch_dashboard" "main_dashboard" {
  dashboard_name = "main_dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            [ "AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.webcluster.name, "ServiceName", aws_ecs_service.webservice.name ]
          ]
          period = 60
          stat = "Average"
          region = "eu-central-1"
          title = "CPU Webserver"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            [ "CustomSecurity", "ssh_unauthorized_count" ]
          ]
          period = 60
          stat = "Sum"
          region = "eu-central-1"
          title = "SSH Unauthorized Attempts"
        }
      }
    ]
  })
}
