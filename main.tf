terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
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

data "aws_iam_policy_document" "falconPipelineIAMPolicy" {
    statement {
      effect = "Allow"
      principals {
        type = "Service"
        identifiers = ["codepipeline.amazonaws.com"]
      }
      actions = ["sts:AssumeRole"]
    }
}

resource "aws_iam_role" "falconPipelineRole" {
  name = "falconPipelineRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement [{
      effect = "Allow",
      principal = {
        Service = "codepipeline.amazonaws.com"
      },
      Action = "sts:AssumeRole"
      }]
    })
  }

resource "aws_iam_role_policy_attachment" "falconPipelinePolicyAttachment" {
 role = aws_iam_role.falconPipelineRole.name
 policy_arn = "arn:aws:iam::aws:policy/AWSCodePipelineFullAccess"
}



# data "aws_iam_policy_document" "falconPipelinePolicy" {
#     statement {
#         effect = "Allow"

#         actions = [
#             "ecr:GetAuthorizationToken",
#             "ecr:BatchCheckLayerAvailability",
#             "ecr:GetDownloadUrlForLayer",
#             "ecr:BatchGetImage",
#             "logs:CreateLogStream",
#             "logs:PutLogEvents",
#             "logs:CreateLogGroup"
#             ]

#         resources = [
#             "*",
#             "arn:aws:logs:*:*:log-group:/aws/codebuild/*",
#             "arn:aws:logs:*:*:log-group:/aws/codepipeline/*",
#             "arn:aws:ecr:*:*:repository/*"
#         ]
#     }
# }
  
