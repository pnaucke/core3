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

  # 🔧 INLINE POLICY TOEGEVOEGD - Dit lost de 403-fout op
  inline_policy {
    name = "backup-vault-creation-permissions"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "backup-storage:MountBackupVault",      # Nodig voor vault creatie
            "kms:DescribeKey",                      # Nodig voor vault creatie
            "kms:GenerateDataKey*",                 # Nodig voor vault creatie
            "kms:Decrypt",                          # Nodig voor vault creatie
            "backup:ListBackupVaults"              # Algemeen nuttige rechten
          ]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }
}