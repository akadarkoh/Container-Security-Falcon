
data "aws_iam_policy_document" "codepipeline_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "codepipeline_role" {
  name               = "falcon-codepipeline-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_role_policy.json
}

data "aws_iam_policy_document" "codepipeline_policy" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject",
    ]
    resources = [
      aws_s3_bucket.codepipeline_bucket.arn,
      "${aws_s3_bucket.codepipeline_bucket.arn}/*",
    ]
  }

  statement {
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "ecr:DescribeImages",
    ]
    resources = [data.aws_ecr_repository.falcon_ecr_repository.arn]
  }

  statement {
    sid = "TaskDefinitionPermissions"
    actions = [
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition"
    ]
    resources = ["*"]
  }

  statement {
    sid = "ECSServicePermissions"
    actions = [
      "ecs:DescribeServices",
      "ecs:UpdateService"
    ]
    resources = ["arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:service/${aws_ecs_cluster.falcon_cluster.name}/${aws_ecs_service.falcon_service.name}"]
  }

  statement {
    actions = [
      "ecs:DescribeClusters"
    ]
    resources = ["arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:cluster/${aws_ecs_cluster.falcon_cluster.name}"]
  }

  statement {
    sid = "ECSTagResource"
    actions = [
      "ecs:TagResource"
    ]
    resources = ["arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:task-definition/*:*"]
    condition {
      test     = "StringEquals"
      variable = "ecs:CreateAction"
      values   = ["RegisterTaskDefinition"]
    }
  }

  statement {
    sid = "AllowPassRoles"
    actions = [
      "iam:PassRole",
    ]
    resources = [
      aws_iam_role.falcon_ecs_task_execution_role.arn,
      aws_iam_role.falcon_ecs_task_role.arn,
    ]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values = [
        "ecs.amazonaws.com",
        "ecs-tasks.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_policy" "codepipeline_policy" {
  name        = "falcon-codepipeline-policy"
  description = "Policy for Falcon CodePipeline role"
  policy      = data.aws_iam_policy_document.codepipeline_policy.json

  tags = {
    Name = "falcon-codepipeline-policy"
  }
}

resource "aws_iam_role_policy_attachment" "codepipeline_policy_attachment" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}

data "aws_iam_policy_document" "codebuild_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codebuild_role" {
  name               = "falcon-codebuild-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_role_policy.json
}

data "aws_iam_policy_document" "codebuild_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:GetObjectVersion",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation",
    ]
    resources = [
      aws_s3_bucket.codepipeline_bucket.arn,
      "${aws_s3_bucket.codepipeline_bucket.arn}/*",
      aws_s3_bucket.website_bucket.arn,
      "${aws_s3_bucket.website_bucket.arn}/*",
    ]
  }

  statement {
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
    ]
    resources = [data.aws_ecr_repository.falcon_ecr_repository.arn]
  }
}

resource "aws_iam_policy" "codebuild_policy" {
  name        = "falcon-codebuild-policy"
  description = "Policy for Falcon CodeBuild role"
  policy      = data.aws_iam_policy_document.codebuild_policy.json

  tags = {
    Name = "falcon-codebuild-policy"
  }
}

resource "aws_iam_role_policy_attachment" "codebuild_policy_attachment" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_policy.arn
}

data "aws_iam_policy_document" "ecs_task_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "falcon_ecs_task_role" {
  name               = "falcon-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_role_policy.json
}
