# soar.tf - Database auto-restart met complete logging
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

# 3. Lambda code INLINE met database status logging
data "archive_file" "lambda_code" {
  type        = "zip"
  output_path = "lambda_db_restart.zip"

  source {
    content  = <<EOF
import boto3
import json
import datetime
import os

def write_status_log(message, status_type="INFO"):
    """Schrijft een log entry naar de database status log group"""
    try:
        logs_client = boto3.client('logs')
        log_group = '/innovatech/database/status'
        log_stream = 'events'
        
        # Maak timestamp
        timestamp = int(datetime.datetime.now().timestamp() * 1000)
        
        # Schrijf log event
        logs_client.put_log_events(
            logGroupName=log_group,
            logStreamName=log_stream,
            logEvents=[
                {
                    'timestamp': timestamp,
                    'message': f"[{status_type}] {message}"
                }
            ]
        )
        print(f"Status gelogd: {message}")
    except logs_client.exceptions.ResourceNotFoundException:
        # Maak log stream aan als die niet bestaat
        try:
            logs_client.create_log_stream(
                logGroupName=log_group,
                logStreamName=log_stream
            )
            # Probeer opnieuw
            logs_client.put_log_events(
                logGroupName=log_group,
                logStreamName=log_stream,
                logEvents=[
                    {
                        'timestamp': timestamp,
                        'message': f"[{status_type}] {message}"
                    }
                ]
            )
        except Exception as e:
            print(f"Kan geen log stream aanmaken: {e}")
    except Exception as e:
        print(f"Log schrijven mislukt: {e}")

def lambda_handler(event, context):
    db_id = "hr-database"
    rds = boto3.client('rds')
    
    try:
        # Log dat Lambda is getriggerd
        trigger_type = event.get('detail-type', 'Direct')
        write_status_log(f"Lambda getriggerd door: {trigger_type}", "INFO")
        
        # Check database status
        response = rds.describe_db_instances(DBInstanceIdentifier=db_id)
        status = response['DBInstances'][0]['DBInstanceStatus']
        
        write_status_log(f"Database status: {status}", "INFO")
        
        if status == "stopped":
            write_status_log("Database is gestopt. Start automatisch...", "CRITICAL")
            print(f"Database {db_id} is stopped. Starting...")
            
            # Start database
            start_response = rds.start_db_instance(DBInstanceIdentifier=db_id)
            write_status_log("Database start commando uitgevoerd", "ACTION")
            
            return {
                "status": "started", 
                "message": f"Database {db_id} is being started"
            }
        else:
            write_status_log(f"Geen actie nodig - status is {status}", "INFO")
            print(f"Database status: {status}. No action needed.")
            return {"status": "ok", "message": f"Database is {status}"}
            
    except rds.exceptions.DBInstanceNotFoundFault:
        error_msg = "Database niet gevonden!"
        write_status_log(error_msg, "ERROR")
        return {"status": "error", "message": error_msg}
        
    except Exception as e:
        error_msg = f"Fout: {str(e)}"
        write_status_log(error_msg, "ERROR")
        print(f"Error: {str(e)}")
        raise e
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

# 5. EventBridge regel - DE TRIGGER
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