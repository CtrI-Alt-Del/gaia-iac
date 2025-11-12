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

# 1) SNS Topic
resource "aws_sns_topic" "gaia_panel_alerts" {
  name = "${terraform.workspace}-gaia-panel-alerts"
}

# 2) Assinatura por e-mail (CONFIRME o e-mail após o apply)
resource "aws_sns_topic_subscription" "gaia_panel_email" {
  topic_arn = aws_sns_topic.gaia_panel_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# 3) Alarme de CPU do serviço "panel"
resource "aws_cloudwatch_metric_alarm" "gaia_panel_cpu_gt60" {
  alarm_name          = "${terraform.workspace}-gaia-panel-cpu-gt-60"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  period              = 60 # cada ponto = 60s
  evaluation_periods  = 1  # precisa de 1 ponto
  datapoints_to_alarm = 1  # (opcional) dispara com 1 ponto
  threshold           = 60
  metric_name         = "ECSServiceAverageCPUUtilization"
  namespace           = "AWS/ECS"
  statistic           = "Average"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.panel_service.name
  }

  alarm_description = "CPU média do serviço panel >= 60% por 5 min"
  alarm_actions     = [aws_sns_topic.gaia_panel_alerts.arn] # envia e-mail ao entrar em ALARM
  ok_actions        = [aws_sns_topic.gaia_panel_alerts.arn] # (opcional) e-mail quando voltar ao normal

  treat_missing_data = "notBreaching" # não alarme por falta de dado
}

# variável para o e-mail
variable "alert_email" {
  type        = string
  description = "E-mail que receberá os alertas"
  default     = "gaia2.ctrlaltdel@gmail.com"
}
