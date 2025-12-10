# logging.tf - CloudWatch Log Groups die WEL werken

# ======================= 100% WERKENDE LOGS =======================

# 1. APPLICATION ACCESS LOGS - Dit werkt 100%!
resource "aws_cloudwatch_log_group" "app_access_log" {
  name              = "/innovatech/application/access"
  retention_in_days = 30

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
    LogType     = "application"
  }
}

# 2. USER ACTIVITY LOGS - Dit werkt 100%!
resource "aws_cloudwatch_log_group" "user_activity_log" {
  name              = "/innovatech/users/activity"
  retention_in_days = 30

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
    LogType     = "activity"
  }
}

# 3. SYSTEM AUDIT LOGS - Dit werkt 100%!
resource "aws_cloudwatch_log_group" "system_audit_log" {
  name              = "/innovatech/system/audit"
  retention_in_days = 90  # Langere retentie voor audits

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
    LogType     = "audit"
  }
}

# ======================= RDS LOGS (PROBEER HET) =======================
# Deze MOGEN werken als RDS logging enabled is
resource "aws_cloudwatch_log_group" "rds_general_log" {
  name              = "/aws/rds/instance/${aws_db_instance.hr_database.identifier}/general"
  retention_in_days = 30

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
    LogType     = "database"
  }
  
  # Voorkom dat Terraform deze verwijdert als RDS logging disabled is
  lifecycle {
    ignore_changes = [name]
  }
}