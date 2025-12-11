# Backup systeem voor RDS database

# 1. IAM Role voor AWS Backup
resource "aws_iam_role" "backup_role" {
  name = "aws-backup-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "backup_policy" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

# 2. Backup Vault (waar backups worden opgeslagen)
resource "aws_backup_vault" "rds_backup_vault" {
  name        = "rds-daily-backup-vault"
  # De 'kms_key_arn' regel is verwijderd. AWS Backup gebruikt nu zijn standaard key.

  tags = {
    Name      = "rds-daily-backup-vault"
    ManagedBy = "terraform"
  }
}

# 3. Backup Plan (dagelijks om 05:00 UTC)
resource "aws_backup_plan" "daily_backup" {
  name = "rds-daily-backup-plan"

  rule {
    rule_name         = "daily-rule"
    target_vault_name = aws_backup_vault.rds_backup_vault.name
    schedule          = "cron(0 5 * * ? *)"  # Elke dag om 05:00 UTC
    
    lifecycle {
      delete_after = 7  # Bewaar backups 7 dagen
    }
  }

  tags = {
    Name      = "rds-daily-backup-plan"
    ManagedBy = "terraform"
  }
}

# 4. Koppel RDS database aan backup plan
resource "aws_backup_selection" "rds_selection" {
  name         = "rds-backup-selection"
  plan_id      = aws_backup_plan.daily_backup.id
  iam_role_arn = aws_iam_role.backup_role.arn

  resources = [
    aws_db_instance.hr_database.arn
  ]
}

# 5. CloudWatch Log Group voor backup logging
resource "aws_cloudwatch_log_group" "backup_logs" {
  name              = "/aws/backup/rds-backup"
  retention_in_days = 30

  tags = {
    Name      = "rds-backup-logs"
    ManagedBy = "terraform"
    LogType   = "backup"
  }
}