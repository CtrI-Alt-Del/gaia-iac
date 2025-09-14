resource "aws_ecr_repository" "gaia_server_ecr_repository" {
  name                 = "${terraform.workspace}-gaia-server-ecr-repository"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    IAC = true
    Environment = terraform.workspace
  }
}

resource "aws_ecr_repository" "gaia_panel_ecr_repository" {
  name                 = "${terraform.workspace}-gaia-panel-ecr-repository"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    IAC = true
    Environment = terraform.workspace
  }
}