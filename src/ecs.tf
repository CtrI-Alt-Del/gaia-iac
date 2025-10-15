resource "aws_ecs_cluster" "main" {
  name = "${terraform.workspace}-gaia-cluster"

  tags = {
    IAC = true
  }
}

resource "aws_ecs_service" "panel_service" {
  name            = "${terraform.workspace}-${var.gaia_panel_container_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.gaia_panel_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

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

  tags = {
    IAC = true
  }
}

resource "aws_ecs_service" "gaia_server_service" {
  name            = "${terraform.workspace}-${var.gaia_server_container_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.gaia_server_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_groups  = [aws_security_group.gaia_server_sg.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.gaia_server_sd.arn
  }

  tags = {
    IAC = true
  }
}

resource "aws_ecs_service" "gaia_collector_service" {
  name            = "${terraform.workspace}-gaia-collector-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.gaia_collector_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_groups  = [aws_security_group.gaia_collector_sg.id]
    assign_public_ip = false
  }

  tags = {
    IAC = true
  }
}

resource "aws_ecs_task_definition" "gaia_panel_task" {
  family                   = "${terraform.workspace}-gaia-panel-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.gaia_panel_container_cpu
  memory                   = var.gaia_panel_container_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

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
        value = "http://${aws_service_discovery_service.gaia_server_sd.name}.${aws_service_discovery_private_dns_namespace.gaia_ns.name}:${var.gaia_server_container_port}"
      },
    ]
    secrets = [
      {
        name      = "VITE_CLERK_PUBLISHABLE_KEY",
        valueFrom = "${data.aws_secretsmanager_secret.clerk_credentials.arn}:CLERK_PUBLISHABLE_KEY::"
      },
      {
        name      = "CLERK_SECRET_KEY",
        valueFrom = "${data.aws_secretsmanager_secret.clerk_credentials.arn}:CLERK_SECRET_KEY::"
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
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.gaia_server_container_cpu
  memory                   = var.gaia_server_container_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

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
        value = "postgresql://${aws_db_instance.postgres_db.username}:${aws_db_instance.postgres_db.password}@${aws_db_instance.postgres_db.endpoint}/${aws_db_instance.postgres_db.db_name}"
      },
      { name = "POSTGRES_DATABASE", value = aws_db_instance.postgres_db.db_name },
      { name = "POSTGRES_USER", value = aws_db_instance.postgres_db.username }
    ]
    secrets = [
      {
        name      = "POSTGRES_PASSWORD",
        valueFrom = aws_secretsmanager_secret.postgres_db_credentials.arn
      },
      {
        name      = "CLERK_PUBLISHABLE_KEY",
        valueFrom = "${data.aws_secretsmanager_secret.clerk_credentials.arn}:CLERK_PUBLISHABLE_KEY::"
      },
      {
        name      = "CLERK_SECRET_KEY",
        valueFrom = "${data.aws_secretsmanager_secret.clerk_credentials.arn}:CLERK_SECRET_KEY::"
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

  container_definitions = jsonencode([{
    name      = "${terraform.workspace}-${var.gaia_collector_container_name}"
    image     = "${aws_ecr_repository.gaia_collector_ecr_repository.repository_url}:latest"
    essential = true

    environment = []

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
