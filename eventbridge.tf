resource "aws_cloudwatch_event_rule" "ecr_image_push" {
  name        = "falcon-ecr-image-push"
  description = "Trigger CodePipeline on ECR image push"

  event_pattern = jsonencode({
    source      = ["aws.ecr"]
    detail-type = ["ECR Image Action"]
    detail = {
      action-type     = ["PUSH"]
      repository-name = [data.aws_ecr_repository.falcon_ecr_repository.name]
      image-tag       = ["latest"]
      result          = ["SUCCESS"]
    }
  })

  tags = {
    Name = "falcon-ecr-image-push-rule"
  }
}

resource "aws_cloudwatch_event_target" "codepipeline" {
  rule      = aws_cloudwatch_event_rule.ecr_image_push.name
  target_id = "TriggerCodePipeline"
  arn       = aws_codepipeline.falcon_codepipeline.arn
  role_arn  = aws_iam_role.eventbridge_role.arn
}

resource "aws_iam_role" "eventbridge_role" {
  name = "falcon-eventbridge-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "falcon-eventbridge-role"
  }
}

resource "aws_iam_role_policy" "eventbridge_pipeline_execution" {
  name = "falcon-eventbridge-pipeline-execution"
  role = aws_iam_role.eventbridge_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codepipeline:StartPipelineExecution"
        ]
        Resource = [
          aws_codepipeline.falcon_codepipeline.arn
        ]
      }
    ]
  })
}
