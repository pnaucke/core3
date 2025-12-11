# 1. IAM Role voor AWS Backup (ZONDER inline_policy)
resource "aws_iam_role" "backup_role" {
  name = "aws-backup-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = { Service = "backup.amazonaws.com" }
      }
    ]
  })
}

# 2. AWS Managed Policy attachment
resource "aws_iam_role_policy_attachment" "backup_policy" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

# 3. EXTRA Inline Policy voor backup vault creatie (nieuwe syntax)
resource "aws_iam_role_policy" "backup_vault_creation" {
  name = "backup-vault-creation-permissions"
  role = aws_iam_role.backup_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "backup-storage:MountBackupVault",
          "backup-storage:DeleteBackupVault",
          "backup-storage:DescribeBackupVault",
          "backup:TagResource",
          "kms:DescribeKey",
          "kms:GenerateDataKey*",
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:CreateGrant",
          "kms:RetireGrant"
        ]
        Resource = "*"
      }
    ]
  })
}

# 4. Backup Vault (opslaglocatie)
resource "aws_backup_vault" "rds_backup_vault" {
  name = "rds-daily-backup-vault"
  tags = {
    Name      = "rds-daily-backup-vault"
    ManagedBy = "terraform"
  }
}

# 5. Backup Plan (schema: dagelijks om 05:00, retentie 7 dagen)
resource "aws_backup_plan" "daily_backup" {
  name = "rds-daily-backup-plan"

  rule {
    rule_name         = "daily-rule"
    target_vault_name = aws_backup_vault.rds_backup_vault.name
    schedule          = "cron(0 5 * * ? *)"  # Elke dag om 05:00 UTC
    lifecycle { delete_after = 7 }           # Bewaar 7 dagen
  }

  tags = {
    Name      = "rds-daily-backup-plan"
    ManagedBy = "terraform"
  }
}

# 6. Koppel alleen de RDS database aan het plan
resource "aws_backup_selection" "rds_selection" {
  name         = "rds-backup-selection"
  plan_id      = aws_backup_plan.daily_backup.id
  iam_role_arn = aws_iam_role.backup_role.arn
  resources    = [aws_db_instance.hr_database.arn]
}

# 7. Loggroep voor backup logs
resource "aws_cloudwatch_log_group" "backup_logs" {
  name              = "/aws/backup/rds-backup"
  retention_in_days = 30
  tags = {
    Name      = "rds-backup-logs"
    ManagedBy = "terraform"
    LogType   = "backup"
  }
}

# 8. Metric Filters om SUCCEEDED/FAILED berichten in logs te tellen
resource "aws_cloudwatch_log_metric_filter" "successful_backup" {
  name           = "successful-backup-count"
  pattern        = "SUCCEEDED"
  log_group_name = aws_cloudwatch_log_group.backup_logs.name
  metric_transformation {
    name      = "SuccessfulBackupCount"
    namespace = "Backup"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "failed_backup" {
  name           = "failed-backup-count"
  pattern        = "FAILED"
  log_group_name = aws_cloudwatch_log_group.backup_logs.name
  metric_transformation {
    name      = "FailedBackupCount"
    namespace = "Backup"
    value     = "1"
  }
}

# 9. CloudWatch Alarm dat afgaat bij een mislukte backup
resource "aws_cloudwatch_metric_alarm" "failed_backup_alarm" {
  alarm_name          = "failed-backup-alarm"
  alarm_description   = "Waarschuwt bij een gefaalde RDS backup"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 0  # Alarm bij 1 of meer failures
  period              = 60 # Evalueer per minuut
  statistic           = "Sum"
  metric_name         = "FailedBackupCount"
  namespace           = "Backup"
  alarm_actions       = []  # Vul hier later een SNS Topic ARN in voor meldingen
  treat_missing_data  = "notBreaching" # Negeer periodes zonder data
}