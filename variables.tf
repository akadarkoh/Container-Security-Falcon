# variables.tf
variable "region" {
  type = string
}

variable "ecr_repository_name" {
  type = string
}

variable "ecr_image_tag" {
  type    = string
  default = "latest"
}

variable "github_token" {
  type        = string
  description = "GitHub personal access token for CodePipeline"
  sensitive   = true
}
