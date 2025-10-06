data "aws_ecr_repository" "falcon_ecr_repository" {
  name = var.ecr_repository_name
}
