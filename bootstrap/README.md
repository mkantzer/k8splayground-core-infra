# Project bootstrap

This directory contains an independent terraform configuration for bootstrapping terraform cloud projects and provider authentication. 

It primarily does this via OIDC providers:
- [TF Cloud <-> AWS OIDC documentation](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/aws-configuration)

Additionally, it creates and configures the primary core-infra workspaces used in the rest of this repo.

The backing tf cloud workspace was manually configured, and uses local execution. This allows full bootstrapping using local credentials.