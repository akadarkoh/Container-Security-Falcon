resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "falcon-codepipeline-bucket"

  tags = {
    Name = "falcon-codepipeline-bucket"
  }
}

resource "aws_s3_bucket" "website_bucket" {
  bucket = "falcon-website-bucket"



  tags = {
    Name = "falcon-website-bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "website_bucket" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "website_bucket" {
  bucket = aws_s3_bucket.website_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowPublicRead",
        Effect    = "Allow",
        Principal = "*",
        Action = [
          "s3:GetObject"
        ],
        Resource = "${aws_s3_bucket.website_bucket.arn}/*"
      }
    ]
  })
}
