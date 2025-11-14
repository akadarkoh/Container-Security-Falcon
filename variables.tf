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
