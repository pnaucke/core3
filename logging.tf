# logging.tf

# CloudWatch Log Group voor RDS logs
resource "aws_cloudwatch_log_group" "rds_general_log" {
  name              = "/aws/rds/instance/${aws_db_instance.hr_database.identifier}/general"
  retention_in_days = 30

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Log Group voor slow query logs
resource "aws_cloudwatch_log_group" "rds_slowquery_log" {
  name              = "/aws/rds/instance/${aws_db_instance.hr_database.identifier}/slowquery"
  retention_in_days = 30

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}