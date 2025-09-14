resource "aws_iam_openid_connect_provider" "oidc-git" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  tags = {
    IAC = true
  }
}


resource "aws_iam_role" "gaia_iac_role" {
  name = "gaia-iac-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "sts:AssumeRoleWithWebIdentity",
        Principal = {
          Federated = aws_iam_openid_connect_provider.oidc-git.arn
        },
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          },
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:CtrI-Alt-Del/gaia-iac:*"
          }
        }
      }
    ]
  })

  tags = {
    IAC = true
  }
}


resource "aws_iam_role" "gaia_server_role" {
  name = "gaia-server-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "sts:AssumeRoleWithWebIdentity",
        Principal = {
          Federated = aws_iam_openid_connect_provider.oidc-git.arn
        },
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          },
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:CtrI-Alt-Del/gaia-server:*"
          }
        }
      }
    ]
  })

  tags = {
    IAC = true
  }
}

resource "aws_iam_role_policy" "gaia_server_policy" {
  name = "gaia-server-policy"
  role = aws_iam_role.gaia_server_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "ECSECRPermissions"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:BatchGetImage",
          "ecs:*",
          "iam:PassRole",
          "iam:CreateServiceLinkedRole",
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "gaia_panel_role" {
  name = "gaia-panel-policy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "sts:AssumeRoleWithWebIdentity",
        Principal = {
          Federated = aws_iam_openid_connect_provider.oidc-git.arn
        },
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          },
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:CtrI-Alt-Del/gaia-panel:*"
          }
        }
      }
    ]
  })

   tags = {
    IAC = true
  }
}

resource "aws_iam_role_policy" "gaia_panel_policy" {
  name = "gaia-panel-policy"
  role = aws_iam_role.gaia_panel_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "ECSECRPermissions"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:BatchGetImage",
          "ecs:*",
          "iam:PassRole",
          "iam:CreateServiceLinkedRole",
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}