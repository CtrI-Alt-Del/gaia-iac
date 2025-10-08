resource "aws_s3_bucket" "terreform_state_bucket" {
  bucket = var.aws_statefile_s3_bucket

  tags = {
    IAC = true
  }
}

resource "aws_s3_bucket_versioning" "terreform_state_bucket_versioning" {
  bucket = aws_s3_bucket.terreform_state_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}
