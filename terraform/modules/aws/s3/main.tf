resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket
  tags = var.tags
}
