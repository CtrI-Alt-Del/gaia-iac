resource "aws_elasticache_replication_group" "elasticache" {
  replication_group_id       = "${terraform.workspace}-elasticache"
  description                = "Cluster ElastiCache Redis para o projeto Gaia"
  node_type                  = var.elasticache_instance_class
  engine                     = "redis"
  port                       = 6379
  automatic_failover_enabled = false
  num_cache_clusters         = 1

  subnet_group_name  = aws_elasticache_subnet_group.elasticache_sng.name
  security_group_ids = [aws_security_group.elasticache_sg.id]

  transit_encryption_enabled = false
  at_rest_encryption_enabled = false

  tags = {
    IAC         = true
    Environment = terraform.workspace
  }
}
