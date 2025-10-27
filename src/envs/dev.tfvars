gaia_server_container_cpu    = 256 # 0.25 vCPU
gaia_server_container_memory = 512 # 512 MiB
server_min_capacity          = 1   # Mínimo de 1 instância
server_max_capacity          = 2   # Máximo de 2 instâncias (permite testar scaling)
gaia_server_app_mode         = "staging"
gaia_server_app_log_level    = "debug"

gaia_panel_container_cpu    = 256 # 0.25 vCPU
gaia_panel_container_memory = 512 # 512 MiB
panel_min_capacity          = 1   # Mínimo de 1 instância
panel_max_capacity          = 2   # Máximo de 2 instâncias

gaia_collector_container_cpu    = 256 # 0.25 vCPU
gaia_collector_container_memory = 512 # 512 MiB
collector_min_capacity          = 1   # Mínimo de 1 instância
collector_max_capacity          = 2   # Máximo de 2 instâncias

rds_instance_class = "db.t4g.micro" # Menor instância
rds_multi_az       = false          # Sem alta disponibilidade

elasticache_instance_class             = "cache.t4g.micro"
elasticache_transit_encryption_enabled = false
elasticache_at_rest_encryption_enabled = false
