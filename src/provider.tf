terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket         = "gaia3-terraform-state-bucket"
    key            = "gaia-terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "gaia-terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region
}
