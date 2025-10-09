resource "aws_sns_topic" "budget_alerts" {
  name = "budget-alerts"

  tags = {
    IAC = true
  }
}

resource "aws_sns_topic_subscription" "email_target" {
  topic_arn = aws_sns_topic.budget_alerts.arn
  protocol  = "email"
  endpoint  = "joaopcarvalho@gmail.com"
}

resource "aws_sns_topic_policy" "budget_policy" {
  arn    = aws_sns_topic.budget_alerts.arn
  policy = data.aws_iam_policy_document.sns_topic_policy_doc.json
}
