terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
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
  
