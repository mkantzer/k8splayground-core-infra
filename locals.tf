locals {
  name = "k8s-playground-${var.env}"
}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}