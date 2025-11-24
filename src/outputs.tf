output "alb_dns_name" {
  description = "DNS público do Application Load Balancer"
  value       = aws_lb.alb.dns_name
}

output "ecr_repository_url" {
  description = "URL do repositório ECR para fazer o push da imagem Docker"
  value       = aws_ecr_repository.gaia_server_ecr_repository.repository_url
}

output "db_endpoint" {
  description = "Endpoint do banco de dados RDS QL"
  value       = aws_db_instance.postgres.endpoint
}

output "db_credentials_secret_arn" {
  description = "ARN do segredo com as credenciais do banco de dados"
  value       = aws_secretsmanager_secret.postgres_credentials.arn
}

output "elasticache_primary_endpoint" {
  description = "O endpoint de conexão para o cluster ElastiCache Redis"
  value       = aws_elasticache_replication_group.elasticache.primary_endpoint_address
}
