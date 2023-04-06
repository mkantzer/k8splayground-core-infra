terraform {
  required_version = "~> 1.4.0"
  cloud {
    organization = "mk5r"
    workspaces {
      tags = [
        "project:k8s-playground",
        "core-infra",
        "cluster",
      ]
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.47"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.10"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.4.1"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.1"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.1"
    }
    http = {
      source  = "terraform-aws-modules/http"
      version = "2.4.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      repo      = "mkantzer/k8splayground-core-infra"
      project   = "k8splayground"
      directory = "root"
      use       = "cluster"
      env       = var.env
      workspace = terraform.workspace
    }
  }
}