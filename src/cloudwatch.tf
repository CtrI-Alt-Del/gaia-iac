resource "aws_cloudwatch_dashboard" "panel_cpu" {
  dashboard_name = "${terraform.workspace}-panel-cpu"
  dashboard_body = jsonencode({
    widgets = [
      {
        "type" : "metric",
        "x" : 0, "y" : 0, "width" : 12, "height" : 6,
        "properties" : {
          "title" : "Panel – CPU % (Service)",
          "view" : "timeSeries",
          "stat" : "Average",
          "region" : var.aws_region,
          "metrics" : [
            [{ "expression" : "m1/m2*100", "label" : "CPU %", "id" : "e1" }],
            ["ECS/ContainerInsights", "CpuUtilized",
              "ClusterName", jsonencode(aws_ecs_cluster.main.name),
              "ServiceName", jsonencode(aws_ecs_service.panel_service.name),
            { "id" : "m1" }],
            [".", "CpuReserved", ".", jsonencode(aws_ecs_cluster.main.name),
              ".", jsonencode(aws_ecs_service.panel_service.name),
            { "id" : "m2" }]
          ],
          "yAxis" : { "left" : { "min" : 0, "max" : 100 } }
        }
      },
      {
        "type" : "metric",
        "x" : 12, "y" : 0, "width" : 12, "height" : 6,
        "properties" : {
          "title" : "Panel – CPU % (TaskDefinitionFamily)",
          "view" : "timeSeries",
          "stat" : "Average",
          "region" : var.aws_region,
          "metrics" : [
            [{ "expression" : "m3/m4*100", "label" : "CPU % (family)", "id" : "e2" }],
            ["ECS/ContainerInsights", "CpuUtilized",
              "ClusterName", jsonencode(aws_ecs_cluster.main.name),
              "TaskDefinitionFamily", jsonencode(aws_ecs_task_definition.gaia_panel_task.family),
            { "id" : "m3" }],
            [".", "CpuReserved", ".",
              jsonencode(aws_ecs_cluster.main.name),
              ".", jsonencode(aws_ecs_task_definition.gaia_panel_task.family),
            { "id" : "m4" }]
          ],
          "yAxis" : { "left" : { "min" : 0, "max" : 100 } }
        }
      }
    ]
  })
}
