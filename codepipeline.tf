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

resource "aws_codepipeline" "falconPipeline" {
  name = "falconPipeline"
  role_arn = aws_iam_role.falconPipelineRole.arn

  artifact_store {
    type = "S3"
    location = aws_s3_bucket.falconPipelineBucket.bucket
  }

  stage {
    name = "Source"
    action {
      category = "Source"
      owner = "ThirdParty"
      name = "Source"
      provider = "GitHub"
      version = "1"
      output_artifacts = ["source_output"]
      configuration = {
        Owner = "akadarkoh2001"
        Repo = "Container-Falcon-Security"
        Branch = "main"
        OAuthToken = var.github_token
    }

  }
  }

  stage {
    name = "Build"
    action {
      name = "DockerBuild"
      category = "Build"
      owner = "AWS"
      provider = "CodeBuild"
      version = "1"
      input_artifacts = ["source_output"]
      output_artifacts = ["build_output"]
      configuration = {
        ProjectName = aws_codebuild_project.falconBuild.name
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name = "PushToECR"
      category = "Deploy"
      owner = "AWS"
      provider = "CodeDeployToECS"
      version = "1"
      input_artifacts = ["build_output"]
      configuration = {
        ClusterName = var.ecs_cluster_name
        ServiceName = var.ecs_service_name
        Image1ArtifactName = "build_output"
        Image1ContainerName = "falcon-container"
      }
    }
  }
}

