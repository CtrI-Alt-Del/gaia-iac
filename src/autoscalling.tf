resource "aws_appautoscaling_target" "panel_target" {
  max_capacity = var.panel_max_capacity # Lê o máximo do .tfvars
  min_capacity = var.panel_min_capacity # Lê o mínimo do .tfvars
  # Identifica o serviço ECS a ser escalado
  resource_id = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.panel_service.name}"
  # Diz que queremos escalar o número de tasks (DesiredCount)
  scalable_dimension = "ecs:service:DesiredCount"
  # Define o namespace do serviço (ECS)
  service_namespace = "ecs"
}

resource "aws_appautoscaling_policy" "panel_cpu_scaling" {
  name               = "${terraform.workspace}-panel-cpu-scaling"
  policy_type        = "TargetTrackingScaling" # Tipo de política: rastrear uma métrica
  resource_id        = aws_appautoscaling_target.panel_target.resource_id
  scalable_dimension = aws_appautoscaling_target.panel_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.panel_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_target" "server_target" {
  max_capacity       = var.server_max_capacity
  min_capacity       = var.server_min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.gaia_server_service.name}" #
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "server_cpu_scaling" {
  name               = "${terraform.workspace}-server-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.server_target.resource_id
  scalable_dimension = aws_appautoscaling_target.server_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.server_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0 # Pode ajustar este alvo se necessário
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# Arquivo: autoscaling.tf (ou 12-ecs-collector.tf)

# --- Auto Scaling para Gaia Collector ---

resource "aws_appautoscaling_target" "collector_target" {
  max_capacity       = var.collector_max_capacity
  min_capacity       = var.collector_min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.gaia_collector_service.name}" #
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "collector_cpu_scaling" {
  name               = "${terraform.workspace}-collector-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.collector_target.resource_id
  scalable_dimension = aws_appautoscaling_target.collector_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.collector_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    # Para o collector, pode fazer sentido um alvo de CPU mais alto, ex: 80%
    target_value       = 80.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
