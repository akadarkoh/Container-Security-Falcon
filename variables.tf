variable "github_token" {
  description = "GitHub personal access token"
  type = "string"
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type = "string"
}

variable "ecs_service_name" {
  description = "Name of the ECS service"
  type = "string"
}