variable "aws_region" {
  description = "Região da AWS para implantar os recursos"
  type        = string
  default     = "us-east-1"
}

variable "gaia_panel_container_name" {
  description = "Nome do contêiner da aplicação Gaia Panel"
  type        = string
  default     = "gaia-panel"
}

variable "gaia_panel_container_port" {
  description = "Porta que o contêiner da aplicação Gaia Panel expõe"
  type        = number
  default     = 3000
}

variable "gaia_panel_container_cpu" {
  description = "Unidades de CPU para alocar à tarefa Fargate para a aplicação Gaia Panel"
  type        = number
  default     = 512 # 0.5 vCPU
}

variable "gaia_panel_container_memory" {
  description = "Memória em MiB para alocar à tarefa Fargate para a aplicação Gaia Panel"
  type        = number
  default     = 1024 # 1 GB
}

variable "gaia_server_app_mode" {
  description = "Modo de execução da aplicação (ex: development, staging,production)."
  type        = string
  default     = "staging"
}

variable "gaia_server_app_log_level" {
  description = "Nível de log da aplicação (ex: debug, info, error)."
  type        = string
  default     = "debug"
}

variable "gaia_server_container_name" {
  description = "Nome do contêiner da aplicação Gaia Server"
  type        = string
  default     = "gaia-server"
}

variable "gaia_server_container_port" {
  description = "Porta que o contêiner da aplicação Gaia Server expõe"
  type        = number
  default     = 3333
}

variable "gaia_server_container_cpu" {
  description = "Unidades de CPU para alocar à tarefa Fargate para a aplicação Gaia Server"
  type        = number
  default     = 512 # 0.5 vCPU
}

variable "gaia_server_container_memory" {
  description = "Memória em MiB para alocar à tarefa Fargate para a aplicação Gaia Server"
  type        = number
  default     = 1024 # 1 GB
}
