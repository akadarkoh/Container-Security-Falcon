resource "aws_codepipeline" "falcon_codepipeline" {
  name     = "falcon-codepipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "ECR"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName = data.aws_ecr_repository.falcon_ecr_repository.name
        ImageTag       = var.ecr_image_tag
      }
    }
  }

  stage {
    name = "BuildAndScan"

    action {
      name             = "BuildAndScan"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.falcon_codebuild_project.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "DeployToECS"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ClusterName = aws_ecs_cluster.falcon_cluster.name
        ServiceName = aws_ecs_service.falcon_service.name
        FileName    = "imagedefinitions.json"
      }
    }
  }
}
