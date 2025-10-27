resource "aws_appautoscaling_target" "panel_target" {
  max_capacity       = var.panel_max_capacity
  min_capacity       = var.panel_min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.panel_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  tags = {
    IAC         = true
    Environment = terraform.workspace
  }
}

resource "aws_appautoscaling_policy" "panel_cpu_scaling" {
  name               = "${terraform.workspace}-panel-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
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
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.gaia_server_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  tags = {
    IAC         = true
    Environment = terraform.workspace
  }
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
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_target" "collector_target" {
  max_capacity       = var.collector_max_capacity
  min_capacity       = var.collector_min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.gaia_collector_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  tags = {
    IAC         = true
    Environment = terraform.workspace
  }
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
    target_value       = 80.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
