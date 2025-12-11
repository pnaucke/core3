# soar.tf - Database auto-restart met correcte trigger
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

# 2. IAM Policy - permissies voor RDS en CloudWatch Logs
resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda-db-restart-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",
          "rds:StartDBInstance"
        ]
        Resource = "arn:aws:rds:eu-central-1:${data.aws_caller_identity.current.account_id}:db:hr-database"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# 3. Lambda code INLINE - Terraform maakt zelf zip
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

# 4. Lambda functie
resource "aws_lambda_function" "db_restarter" {
  filename      = data.archive_file.lambda_code.output_path
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

  depends_on = [
    aws_iam_role_policy.lambda_policy,
    data.archive_file.lambda_code
  ]
}

# 5. EventBridge regel - DE ECHTE TRIGGER
resource "aws_cloudwatch_event_rule" "db_downtime_rule" {
  name        = "db-downtime-event-rule"
  description = "Triggers when database downtime alarm goes to ALARM state"

  event_pattern = jsonencode({
    source      = ["aws.cloudwatch"]
    detail-type = ["CloudWatch Alarm State Change"]
    detail = {
      alarmName = ["database-downtime-alarm"]
      state = {
        value = ["ALARM"]
      }
    }
  })
}

# 6. EventBridge target dat de Lambda aanroept
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.db_downtime_rule.name
  target_id = "lambda-target"
  arn       = aws_lambda_function.db_restarter.arn
}

# 7. Toestemming voor EventBridge om Lambda aan te roepen
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.db_restarter.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.db_downtime_rule.arn
}