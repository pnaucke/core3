resource "aws_cloudwatch_log_group" "database_status" {
  name              = "/innovatech/database/status"
  retention_in_days = 90

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
    LogType     = "status"
  }
}