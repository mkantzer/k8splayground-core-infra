variable "tf_org_name" {
  type    = string
  default = "mk5r"
}

variable "tf_project_name" {
  type = string
}

variable "core_workspaces" {
  type = map(object({
    env         = string
    description = string
    tags        = list(string)
  }))
}