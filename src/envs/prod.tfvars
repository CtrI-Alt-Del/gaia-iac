gaia_server_container_cpu    = 512
gaia_server_container_memory = 1024
gaia_server_desired_count    = 2
gaia_server_app_mode         = "production"
gaia_server_app_log_level    = "info"

gaia_panel_container_cpu    = 512
gaia_panel_container_memory = 1024
gaia_panel_desired_count    = 1

gaia_collector_container_cpu    = 512
gaia_collector_container_memory = 1024
gaia_collector_desired_count    = 1

rds_instance_class = "db.t3.small"
rds_multi_az       = true

elasticache_instance_class = "cache.t4g.micro"
