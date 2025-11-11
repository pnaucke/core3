# ----------------------
# CloudWatch Dashboard
# ----------------------
resource "aws_cloudwatch_dashboard" "web_dashboard" {
  dashboard_name = "web-servers-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # CPU Usage grafiek (time series)
      {
        type = "metric"
        x = 0
        y = 0
        width = 24
        height = 6
        properties = {
          view = "timeSeries"
          title = "CPU Usage Webservers"
          region = "eu-central-1"
          stacked = false
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.web1.id, { "stat": "Average", "color": "#1f77b4", "label": "Webserver1" }],
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.web2.id, { "stat": "Average", "color": "#ff7f0e", "label": "Webserver2" }]
          ]
          yAxis = { left = { min = 0, max = 100 } }
          period = 60
        }
      },

      # CPU single value Webserver1
      {
        type = "metric"
        x = 0
        y = 7
        width = 12
        height = 4
        properties = {
          view = "singleValue"
          title = "Webserver1 CPU"
          region = "eu-central-1"
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.web1.id, { "stat": "Average", "label": "CPU %" }]
          ]
          period = 60
          stat = "Average"
        }
      },

      # CPU single value Webserver2
      {
        type = "metric"
        x = 12
        y = 7
        width = 12
        height = 4
        properties = {
          view = "singleValue"
          title = "Webserver2 CPU"
          region = "eu-central-1"
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.web2.id, { "stat": "Average", "label": "CPU %" }]
          ]
          period = 60
          stat = "Average"
        }
      },

      # Uptime Webserver1 (Up / Down)
      {
        type = "metric"
        x = 0
        y = 12
        width = 12
        height = 4
        properties = {
          view = "singleValue"
          title = "Webserver1 Uptime"
          region = "eu-central-1"
          metrics = [
            # ALB UnhealthyHostCount metric
            ["AWS/ApplicationELB", "UnhealthyHostCount", "TargetGroup", aws_lb_target_group.web_tg.arn_suffix, "LoadBalancer", aws_lb.web_lb.arn_suffix, { "id": "m1" }],
            # Metric math: 1 = Up, 0 = Down
            [{ "expression": "IF(m1==0,1,0)", "label": "Up", "color": "#2ca02c" }]
          ]
          period = 60
          stat = "Maximum"
          yAxis = { left = { min = 0, max = 1 } }
        }
      },

      # Uptime Webserver2 (Up / Down)
      {
        type = "metric"
        x = 12
        y = 12
        width = 12
        height = 4
        properties = {
          view = "singleValue"
          title = "Webserver2 Uptime"
          region = "eu-central-1"
          metrics = [
            ["AWS/ApplicationELB", "UnhealthyHostCount", "TargetGroup", aws_lb_target_group.web_tg.arn_suffix, "LoadBalancer", aws_lb.web_lb.arn_suffix, { "id": "m2" }],
            [{ "expression": "IF(m2==0,1,0)", "label": "Up", "color": "#2ca02c" }]
          ]
          period = 60
          stat = "Maximum"
          yAxis = { left = { min = 0, max = 1 } }
        }
      }
    ]
  })
}
