resource "aws_codecommit_repository" "falcon_codecommit_repo" {
  repository_name = "falcon-app-repo"
  description     = "Source code for the Falcon application"
}
