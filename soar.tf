# soar.tf - Database auto-restart na 1 minuut downtime
# Data voor account ID
data "aws_caller_identity" "current" {}

# 1. IAM Role voor Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda-db-restart-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# 2. IAM Policy - alleen starten van HR database
resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda-db-restart-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "rds:DescribeDBInstances",
        "rds:StartDBInstance"
      ]
      Resource = "arn:aws:rds:eu-central-1:${data.aws_caller_identity.current.account_id}:db:hr-database"
    }]
  })
}

# 3. Lambda functie (simpele Python code)
resource "aws_lambda_function" "db_restarter" {
  filename      = "lambda_db_restart.zip"
  function_name = "db-restarter"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.9"
  timeout       = 30

  environment {
    variables = {
      DB_NAME = "hr-database"
    }
  }
}

# 4. Lambda code INLINE - Terraform maakt zelf zip
data "archive_file" "lambda_code" {
  type        = "zip"
  output_path = "lambda_db_restart.zip"

  source {
    content  = <<EOF
import boto3
import json

def lambda_handler(event, context):
    db_id = "hr-database"
    rds = boto3.client('rds')
    
    try:
        # Check database status
        response = rds.describe_db_instances(DBInstanceIdentifier=db_id)
        status = response['DBInstances'][0]['DBInstanceStatus']
        
        if status == "stopped":
            print(f"Database {db_id} is stopped. Starting...")
            rds.start_db_instance(DBInstanceIdentifier=db_id)
            return {"status": "started", "message": f"Database {db_id} is being started"}
        else:
            print(f"Database status: {status}. No action needed.")
            return {"status": "ok", "message": f"Database is {status}"}
            
    except Exception as e:
        print(f"Error: {str(e)}")
        return {"status": "error", "message": str(e)}
EOF
    filename = "index.py"
  }
}

# 5. Toestemming voor CloudWatch om Lambda aan te roepen
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.db_restarter.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_metric_alarm.database_downtime_alarm.arn
}

# 6. Update het bestaande alarm in monitoring.tf
#    (Terraform zal dit overschrijven)
resource "aws_cloudwatch_metric_alarm" "database_downtime_alarm" {
  alarm_name          = "database-downtime-alarm"
  alarm_description   = "Database is down (geen CPU metrics) - start automatisch na 1 min"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1    # 1 minuut
  threshold           = 0.01
  period              = 60   # 60 seconden
  
  metric_name = "CPUUtilization"
  namespace   = "AWS/RDS"
  statistic   = "Average"
  
  dimensions = {
    DBInstanceIdentifier = "hr-database"
  }
  
  treat_missing_data = "breaching"
  
  # Belangrijk: Lambda + SNS samen
  alarm_actions = [
    aws_sns_topic.alarms.arn,
    aws_lambda_function.db_restarter.arn
  ]
  ok_actions    = [aws_sns_topic.alarms.arn]
}