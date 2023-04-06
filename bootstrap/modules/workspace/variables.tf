variable "organization" {
  type = string
}

variable "aws_oidc_provider_arn" {
  type = string
}

variable "aws_oidc_provider_client_id_list" {
  type = list(string)
}

variable "tfc_hostname" {
  type = string
}

variable "project_name" {
  type = string
}

variable "project_id" {
  type = string
}

variable "name" {
  type = string
}

variable "description" {
  type = string
}

variable "tags" {
  type = list(string)
}




