resource "aws_codestarconnections_connection" "github_connection" {
  name          = "falcon-github-connection"
  provider_type = "GitHub"
}
