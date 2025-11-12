resource "aws_lb" "alb" {
  name               = "${terraform.workspace}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = {
    IAC         = true
    Environment = terraform.workspace
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gaia_panel_tg.arn
  }
}

resource "aws_lb_target_group" "gaia_server_tg" {
  name        = "${terraform.workspace}-gaia-server-tg"
  port        = var.gaia_server_container_port #
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id #
  target_type = "ip"

  health_check {
    path                = "/server/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 2
  }

  tags = {
    IAC         = true
    Environment = terraform.workspace
  }
}

resource "aws_lb_target_group" "gaia_panel_tg" {
  name        = "${terraform.workspace}-gaia-panel-tg"
  port        = var.gaia_panel_container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path = "/auth/sign-in"
  }

  tags = {
    IAC = true
  }
}

resource "aws_lb_listener_rule" "gaia_server_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gaia_server_tg.arn
  }

  condition {
    path_pattern {
      values = ["/server/*"]
    }
  }
}

