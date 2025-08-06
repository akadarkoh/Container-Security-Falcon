resource "aws_codebuild_project" "DockerBuild" {
  name = "docker-image-builder"
  service_role = aws_iam_role.falconPipelineRole.arn
  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image = "aws/codebuild/standard:7.0"
    type = "LINUX_CONTAINER"
    privileged_mode = true
  }

  source {
    type = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }
}

