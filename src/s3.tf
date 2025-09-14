resource "aws_s3_bucket" "terreform_state_bucket" {
  bucket = "${terraform.workspace}-terreform-state-bucket"
  force_destroy = true

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    IAC = true
    Environment = terraform.workspace
  }
}

resource "aws_s3_bucket_versioning" "terreform_state_bucket_versioning" {
  bucket = aws_s3_bucket.terreform_state_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}