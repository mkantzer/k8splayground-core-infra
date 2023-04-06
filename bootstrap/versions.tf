terraform {
  required_version = "~> 1.4.0"
  cloud {
    organization = "mk5r"
    workspaces {
      name = "bootstrap-k8s-playground"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.47"
    }
    tfe = {
      version = "~> 0.43.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
  default_tags {
    tags = {
      repo      = "mkantzer/k8splayground-core-infra"
      project   = "k8splayground"
      directory = "bootstrap"
      use       = "bootstrap"
      workspace = terraform.workspace
    }
  }
}

provider "tfe" {
  organization = "mk5r"
}