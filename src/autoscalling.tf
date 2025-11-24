resource "aws_appautoscaling_target" "server" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.gaia_server_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = 1
  max_capacity       = 4
}

resource "aws_appautoscaling_policy" "server_cpu_tgt" {
  name               = "server-cpu-60"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.server.resource_id
  scalable_dimension = aws_appautoscaling_target.server.scalable_dimension

  target_tracking_scaling_policy_configuration {
    target_value = 60
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_out_cooldown = 60
    scale_in_cooldown  = 120
  }
}

resource "aws_appautoscaling_target" "panel" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.panel_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.panel_min_capacity
  max_capacity       = var.panel_max_capacity
}
resource "aws_appautoscaling_policy" "panel_cpu_tgt" {
  name               = "panel-cpu-60"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.panel.resource_id
  scalable_dimension = aws_appautoscaling_target.panel.scalable_dimension
  target_tracking_scaling_policy_configuration {
    target_value = 60
    predefined_metric_specification { predefined_metric_type = "ECSServiceAverageCPUUtilization" }
    scale_out_cooldown = 60
    scale_in_cooldown  = 120
  }
}

# COLLECTOR (pode usar cooldown-in maior)
resource "aws_appautoscaling_target" "collector" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.gaia_collector_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.collector_min_capacity
  max_capacity       = var.collector_max_capacity
}
resource "aws_appautoscaling_policy" "collector_cpu_tgt" {
  name               = "collector-cpu-60"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.collector.resource_id
  scalable_dimension = aws_appautoscaling_target.collector.scalable_dimension
  target_tracking_scaling_policy_configuration {
    target_value = 60
    predefined_metric_specification { predefined_metric_type = "ECSServiceAverageCPUUtilization" }
    scale_out_cooldown = 60
    scale_in_cooldown  = 180
  }
}
