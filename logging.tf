# logging.tf - Alles voor database logging

# IAM Rol voor RDS CloudWatch Logging
resource "aws_iam_role" "rds_cloudwatch_role" {
  name = "rds-cloudwatch-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "rds-cloudwatch-role"
  }
}

resource "aws_iam_role_policy_attachment" "rds_cloudwatch_policy" {
  role       = aws_iam_role.rds_cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# CloudWatch Log Group voor RDS general logs
resource "aws_cloudwatch_log_group" "rds_general_log" {
  name              = "/aws/rds/instance/${aws_db_instance.hr_database.identifier}/general"
  retention_in_days = 30

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# CloudWatch Log Group voor RDS slow query logs
resource "aws_cloudwatch_log_group" "rds_slowquery_log" {
  name              = "/aws/rds/instance/${aws_db_instance.hr_database.identifier}/slowquery"
  retention_in_days = 30

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}