variable "aws_region" {
  type = string
  default = "eu-west-1"
}

resource "aws_cloudwatch_log_group" "vpc_flowlogs" {
  name = "/aws/vpc/flowlogs"
  retention_in_days = 7
}

resource "aws_iam_role" "flowlog_role" {
  name = "flowlog_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "flowlog_policy" {
  name = "flowlog_policy"
  role = aws_iam_role.flowlog_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "${aws_cloudwatch_log_group.vpc_flowlogs.arn}:*"
      }
    ]
  })
}

resource "aws_flow_log" "vpc_flow" {
  log_destination      = aws_cloudwatch_log_group.vpc_flowlogs.arn
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.main.id
  iam_role_arn         = aws_iam_role.flowlog_role.arn
}

resource "aws_cloudwatch_log_metric_filter" "ssh_unauthorized_filter" {
  name           = "ssh_unauthorized"
  log_group_name = aws_cloudwatch_log_group.vpc_flowlogs.name

  pattern = "{ $.dstPort = 22 }"

  metric_transformation {
    name      = "ssh_unauthorized_count"
    namespace = "custom"
    value     = "1"
  }
}

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

  alarm_description = "CPU boven tachtig procent"
}

resource "aws_cloudwatch_metric_alarm" "ssh_unauthorized_alarm" {
  alarm_name          = "ssh_unauthorized_alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 1
  period              = 60
  statistic           = "Sum"
  metric_name         = "ssh_unauthorized_count"
  namespace           = "custom"

  alarm_description = "SSH poging"
}

resource "aws_cloudwatch_dashboard" "main_dashboard" {
  dashboard_name = "web_monitoring"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          region = var.aws_region
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
          title = "CPU gebruik"
          annotations = {}
        }
      },
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          region = var.aws_region
          metrics = [
            [
              "custom",
              "ssh_unauthorized_count"
            ]
          ]
          title = "SSH pogingen"
          annotations = {}
        }
      }
    ]
  })
}
