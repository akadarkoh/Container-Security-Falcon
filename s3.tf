resource "aws_s3_bucket" "codePipelineBucket" {
  bucket = "falcon-pipeline-bucket"
}

resource "aws_s3_bucket_public_access_block" "codePipelineBucketPublicAccessBlock" {
  bucket = aws_s3_bucket.codePipelineBucket.id

  block_public_acls = true
  block_public_policy = true
  ignore_public_acls =true
  restrict_public_buckets = true
}
