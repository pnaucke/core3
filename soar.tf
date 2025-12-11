resource "aws_sns_topic" "alarms" {
  name = "innovatech-alarms"
}

# SNS email subscription
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = "554603@student.fontys.nl"
}