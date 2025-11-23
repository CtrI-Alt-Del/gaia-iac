resource "aws_ecs_cluster" "main" {
  name = "${terraform.workspace}-gaia-cluster"

  tags = {
    IAC = true
  }
}

data "aws_ami" "ecs_optimized_ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

resource "aws_launch_template" "ecs_ec2_template" {
  name_prefix   = "${terraform.workspace}-ecs-"
  image_id      = data.aws_ami.ecs_optimized_ami.id
  instance_type = var.ec2_instance_type

  iam_instance_profile {
    arn = aws_iam_instance_profile.ecs_instance_profile.arn
  }

  network_interfaces {
    security_groups             = [aws_security_group.ecs_host_sg.id]
    associate_public_ip_address = true
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
    echo ECS_AWSVPC_BLOCK_IMDS=true >> /etc/ecs/ecs.config
  EOF
  )

  tags = {
    IAC = true
  }
}

resource "aws_ecs_capacity_provider" "ecs_ec2_cp" {
  name = "${terraform.workspace}-ec2-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs_asg.arn
  }
}

resource "aws_ecs_cluster_capacity_providers" "cluster_cp_association" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = [
    aws_ecs_capacity_provider.ecs_ec2_cp.name,
    "FARGATE",
    "FARGATE_SPOT"
  ]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_ec2_cp.name
    weight            = 1
  }
}

resource "aws_ecs_service" "panel_service" {
  name                   = "${terraform.workspace}-${var.gaia_panel_container_name}-service"
  cluster                = aws_ecs_cluster.main.id
  task_definition        = aws_ecs_task_definition.gaia_panel_task.arn
  desired_count          = var.panel_min_capacity
  enable_execute_command = true
  force_new_deployment   = true
  launch_type            = "FARGATE"

  # capacity_provider_strategy {
  #   capacity_provider = aws_ecs_capacity_provider.ecs_ec2_cp.name
  #   weight            = 1
  # }

  network_configuration {
    subnets          = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups  = [aws_security_group.gaia_panel_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.gaia_panel_tg.arn
    container_name   = "${terraform.workspace}-${var.gaia_panel_container_name}"
    container_port   = var.gaia_panel_container_port
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = {
    IAC = true
  }
}

resource "aws_ecs_service" "gaia_server_service" {
  name                   = "${terraform.workspace}-${var.gaia_server_container_name}-service"
  cluster                = aws_ecs_cluster.main.id
  task_definition        = aws_ecs_task_definition.gaia_server_task.arn
  desired_count          = var.server_min_capacity
  enable_execute_command = true
  force_new_deployment   = true
  launch_type            = "FARGATE"

  # capacity_provider_strategy {
  #   capacity_provider = aws_ecs_capacity_provider.ecs_ec2_cp.name
  #   weight            = 1
  # }

  network_configuration {
    subnets          = [aws_subnet.public_a.id, aws_subnet.public_b.id] #
    security_groups  = [aws_security_group.gaia_server_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.gaia_server_tg.arn
    container_name   = "${terraform.workspace}-${var.gaia_server_container_name}"
    container_port   = var.gaia_server_container_port
  }

  lifecycle {
    ignore_changes = [desired_count]
  }


  tags = {
    IAC = true
  }
}

resource "aws_ecs_service" "gaia_collector_service" {
  name                   = "${terraform.workspace}-gaia-collector-service"
  cluster                = aws_ecs_cluster.main.id
  task_definition        = aws_ecs_task_definition.gaia_collector_task.arn
  desired_count          = var.collector_min_capacity
  enable_execute_command = true
  force_new_deployment   = true
  launch_type            = "FARGATE"

  # capacity_provider_strategy {
  #   capacity_provider = aws_ecs_capacity_provider.ecs_ec2_cp.name
  #   weight            = 1
  # }
  network_configuration {
    subnets          = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups  = [aws_security_group.gaia_collector_sg.id]
    assign_public_ip = true
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = {
    IAC = true
  }
}

resource "aws_ecs_task_definition" "gaia_panel_task" {
  family                   = "${terraform.workspace}-gaia-panel-task"
  network_mode             = "awsvpc"
  cpu                      = var.gaia_panel_container_cpu
  memory                   = var.gaia_panel_container_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  requires_compatibilities = ["FARGATE"]

  container_definitions = jsonencode([{
    name      = "${terraform.workspace}-${var.gaia_panel_container_name}"
    image     = "${aws_ecr_repository.gaia_panel_ecr_repository.repository_url}:latest"
    essential = true
    portMappings = [{
      containerPort = var.gaia_panel_container_port
    }]
    environment = [
      {
        name  = "VITE_GAIA_SERVER_URL",
        value = "http://${aws_lb.alb.dns_name}/server"
      },
    ]
    secrets = [
      {
        name      = "VITE_CLERK_PUBLISHABLE_KEY",
        valueFrom = "${data.aws_secretsmanager_secret.clerk_secrets.arn}:CLERK_PUBLISHABLE_KEY::"
      },
      {
        name      = "CLERK_SECRET_KEY",
        valueFrom = "${data.aws_secretsmanager_secret.clerk_secrets.arn}:CLERK_SECRET_KEY::"
      }
    ]
    logConfiguration = {
      logDriver = "awslogs",
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.gaia_panel_logs.name,
        "awslogs-region"        = var.aws_region,
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = {
    IAC         = true
    Environment = terraform.workspace
  }
}

resource "aws_ecs_task_definition" "gaia_server_task" {
  family                   = "${terraform.workspace}-gaia-server-task"
  network_mode             = "awsvpc"
  cpu                      = var.gaia_server_container_cpu
  memory                   = var.gaia_server_container_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  requires_compatibilities = ["FARGATE"]

  container_definitions = jsonencode([{
    name      = "${terraform.workspace}-${var.gaia_server_container_name}"
    image     = "${aws_ecr_repository.gaia_server_ecr_repository.repository_url}:latest"
    essential = true
    portMappings = [{
      containerPort = var.gaia_server_container_port
      hostPort      = var.gaia_server_container_port
    }]
    environment = [
      { name = "PORT", value = tostring(var.gaia_server_container_port) },
      { name = "MODE", value = var.gaia_server_app_mode },
      { name = "LOG_LEVEL", value = var.gaia_server_app_log_level },
      { name = "GAIA_PANEL_URL", value = "http://localhost:5173" },
      {
        name  = "POSTGRES_URL",
        value = "postgresql://${aws_db_instance.postgres.username}:${aws_db_instance.postgres.password}@${aws_db_instance.postgres.endpoint}/${aws_db_instance.postgres.db_name}"
      },
      { name = "POSTGRES_DATABASE", value = aws_db_instance.postgres.db_name },
      { name = "POSTGRES_USER", value = aws_db_instance.postgres.username },
      { name = "REDIS_HOST", value = aws_elasticache_replication_group.elasticache.primary_endpoint_address },
      { name = "REDIS_PORT", value = tostring(aws_elasticache_replication_group.elasticache.port) },
    ]
    secrets = [
      {
        name      = "POSTGRES_PASSWORD",
        valueFrom = aws_secretsmanager_secret.postgres_credentials.arn
      },
      {
        name      = "CLERK_PUBLISHABLE_KEY",
        valueFrom = "${data.aws_secretsmanager_secret.clerk_secrets.arn}:CLERK_PUBLISHABLE_KEY::"
      },
      {
        name      = "CLERK_SECRET_KEY",
        valueFrom = "${data.aws_secretsmanager_secret.clerk_secrets.arn}:CLERK_SECRET_KEY::"
      },
      {
        name      = "MONGO_URI",
        valueFrom = "${data.aws_secretsmanager_secret.mongo_secrets.arn}:MONGO_URI::"
      }
    ]
    logConfiguration = {
      logDriver = "awslogs",
      options = {
        "awslogs-group"         = "/ecs/${terraform.workspace}-${var.gaia_server_container_name}",
        "awslogs-region"        = var.aws_region,
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = {
    IAC         = true
    Environment = terraform.workspace
  }
}

resource "aws_ecs_task_definition" "gaia_collector_task" {
  family                   = "${terraform.workspace}-gaia-collector-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.gaia_collector_container_cpu
  memory                   = var.gaia_collector_container_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "${terraform.workspace}-${var.gaia_collector_container_name}"
    image     = "${aws_ecr_repository.gaia_collector_ecr_repository.repository_url}:latest"
    essential = true

    environment = [
      {
        name  = "PORT",
        value = tostring(var.gaia_collector_container_port)
      },
      {
        name  = "GAIA_SERVER_URL",
        value = "http://${aws_service_discovery_service.gaia_server_sd.name}.${aws_service_discovery_private_dns_namespace.gaia_ns.name}:${var.gaia_server_container_port}"
      },
    ]

    secrets = [
      {
        name      = "MQTT_BROKER_URL",
        valueFrom = "${data.aws_secretsmanager_secret.mqtt_broker_secrets.arn}:MQTT_BROKER_URL::"
      },
      {
        name      = "MQTT_USERNAME",
        valueFrom = "${data.aws_secretsmanager_secret.mqtt_broker_secrets.arn}:MQTT_USERNAME::"
      },
      {
        name      = "MQTT_PORT",
        valueFrom = "${data.aws_secretsmanager_secret.mqtt_broker_secrets.arn}:MQTT_PORT::"
      },
      {
        name      = "MQTT_PASSWORD",
        valueFrom = "${data.aws_secretsmanager_secret.mqtt_broker_secrets.arn}:MQTT_PASSWORD::"
      },
      {
        name      = "MQTT_TOPIC",
        valueFrom = "${data.aws_secretsmanager_secret.mqtt_broker_secrets.arn}:MQTT_TOPIC::"
      },
      {
        name      = "MONGO_URI",
        valueFrom = "${data.aws_secretsmanager_secret.mongo_secrets.arn}:MONGO_URI::"
      }
    ]

    logConfiguration = {
      logDriver = "awslogs",
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.gaia_collector_logs.name,
        "awslogs-region"        = var.aws_region,
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

resource "aws_cloudwatch_log_group" "gaia_server_logs" {
  name = "/ecs/${terraform.workspace}-${var.gaia_server_container_name}"

  tags = {
    IAC         = true
    Environment = terraform.workspace
  }
}

resource "aws_cloudwatch_log_group" "gaia_panel_logs" {
  name = "/ecs/${terraform.workspace}-${var.gaia_panel_container_name}"

  tags = {
    IAC         = true
    Environment = terraform.workspace
  }
}

resource "aws_cloudwatch_log_group" "gaia_collector_logs" {
  name = "/ecs/${terraform.workspace}-${var.gaia_collector_container_name}"

  tags = {
    IAC         = true
    Environment = terraform.workspace
  }
}
