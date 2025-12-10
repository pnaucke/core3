# logging.tf - CloudWatch Log Groups

# Test Log Group voor applicatie logging (werkt 100%)
resource "aws_cloudwatch_log_group" "app_test_log" {
  name              = "/innovatech/app/test"
  retention_in_days = 7

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
    Purpose     = "test"
  }
}

# RDS Log Groups (als back-up)
resource "aws_cloudwatch_log_group" "rds_general_log" {
  name              = "/aws/rds/instance/${aws_db_instance.hr_database.identifier}/general"
  retention_in_days = 30

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}