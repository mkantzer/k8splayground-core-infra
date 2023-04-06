variable "env" {
  type = string
}

variable "region" {
  type = string
}

variable "cidr_block" {
  type = string
}

variable "subnet_size" {
  type = number
}

variable "cluster_version" {
  type    = string
  default = "1.24"
}