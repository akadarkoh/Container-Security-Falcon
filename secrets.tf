# Store GitHub token securely in AWS Secrets Manager
resource "aws_secretsmanager_secret" "github_token" {
  name        = "falcon/github-token"
  description = "GitHub personal access token for CodePipeline"

  tags = {
    Name = "falcon-github-token"
  }
}

# Note: The secret value should be set manually via AWS CLI or Console
# aws secretsmanager put-secret-value --secret-id falcon/github-token --secret-string "your-token-here"

# Data source to read the GitHub token from Secrets Manager
data "aws_secretsmanager_secret_version" "github_token" {
  secret_id = aws_secretsmanager_secret.github_token.id
}
