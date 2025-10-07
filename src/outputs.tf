output "alb_dns_name" {
  description = "DNS público do Application Load Balancer"
  value       = aws_lb.alb.dns_name
}

output "ecr_repository_url" {
  description = "URL do repositório ECR para fazer o push da imagem Docker"
  value       = aws_ecr_repository.gaia_server_ecr_repository.repository_url
}

output "db_endpoint" {
  description = "Endpoint do banco de dados RDS PostgreSQL"
  value       = aws_db_instance.postgres_db.endpoint
}

output "db_credentials_secret_arn" {
  description = "ARN do segredo com as credenciais do banco de dados"
  value       = aws_secretsmanager_secret.postgres_db_credentials.arn
}
