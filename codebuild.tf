resource "aws_codebuild_project" "falcon_codebuild_project" {
  name          = "falcon-codebuild-project"
  description   = "CodeBuild project for Falcon container security"
  build_timeout = "5"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "WEBSITE_BUCKET"
      value = aws_s3_bucket.website_bucket.bucket
    }

    environment_variable {
      name  = "ECR_REPOSITORY"
      value = data.aws_ecr_repository.falcon_ecr_repository.name
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

  tags = {
    Name = "falcon-codebuild-project"
  }
}
