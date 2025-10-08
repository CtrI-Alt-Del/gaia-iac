resource "aws_ecr_repository" "gaia_server_ecr_repository" {
  name                 = "${terraform.workspace}-${var.gaia_server_container_name}-ecr-repository"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    IAC         = true
    Environment = terraform.workspace
  }
}

resource "aws_ecr_repository" "gaia_panel_ecr_repository" {
  name                 = "${terraform.workspace}-${var.gaia_panel_container_name}-ecr-repository"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    IAC         = true
    Environment = terraform.workspace
  }
}

