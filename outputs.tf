output "pipeline_url" {
  description = "CodePipeline URL"
  value = "https://console.aws.amazon.com/codesuite/codepipeline/pipelines/${aws_codepipeline.falconPipeline.name}/view"
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value = aws_ecr_repository.foo
}

output "s3_bucket_name" {
  description = "S3 bucket for pipeline artifacts"
  value = aws_s3_bucket.codePipelineBucket.bucket
}

output "codebuild_project_name" {
  description = "CodeBuild project name"
  value = aws_codebuild_project.DockerBuild.name
}