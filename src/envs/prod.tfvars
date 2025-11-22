gaia_server_container_cpu    = 256 # 0.5 vCPU
gaia_server_container_memory = 512 # 1 GB
server_min_capacity          = 2   # Mínimo de 2 instâncias para HA
server_max_capacity          = 4   # Máximo de 4 instâncias (ajuste conforme necessidade)
gaia_server_app_mode         = "production"
gaia_server_app_log_level    = "info" # Logs menos verbosos em produção

gaia_panel_container_cpu    = 256 # 0.5 vCPU
gaia_panel_container_memory = 512 # 1 GB
panel_min_capacity          = 2   # Mínimo de 2 instâncias para HA
panel_max_capacity          = 10  # Permite escalar mais o frontend (ajuste conforme tráfego)

gaia_collector_container_cpu    = 256 # 0.5 vCPU (Mais robusto que dev)
gaia_collector_container_memory = 512 # 1 GB (Mais robusto que dev)
collector_min_capacity          = 2   # Mínimo de 2 instâncias para HA
collector_max_capacity          = 3   # Máximo de 3 instâncias (ajuste conforme carga)

rds_instance_class = "db.t3.micro" # Instância mais robusta que t4g.micro
rds_multi_az       = false         # Habilita Multi-AZ para alta disponibilidade

ec2_instance_type = "t3.medium"

elasticache_instance_class             = "cache.t3.micro"
elasticache_transit_encryption_enabled = true # Habilita criptografia em trânsito
elasticache_at_rest_encryption_enabled = true # Habilita criptografia em repouso
