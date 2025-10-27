# IAM role
resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-falcon-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "codebuild_policy" {
  role = aws_iam_role.codebuild_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Resource = ["*"]
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "s3:*"
        ]
      }

    ]
  })
}

resource "aws_iam_role" "falconPipelineRole" {
  name = "falconPipelineRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
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