# logging.tf - Database uptime en Lambda actie logging

# CENTRALE DATABASE STATUS LOG GROUP
resource "aws_cloudwatch_log_group" "database_status" {
  name              = "/innovatech/database/status"
  retention_in_days = 90  # Bewaar 3 maanden

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
    LogType     = "status"
  }
}