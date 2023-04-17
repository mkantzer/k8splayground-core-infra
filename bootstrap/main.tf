# top-level subdomain for systems

resource "aws_route53_zone" "cluster" {
  name = "clusters.kantzer.io"
}

# Output values needed to delegate subdomain
output "dns_zone_info" {
  description = "Information needed to delegate the subdomain to our hosted zone"
  value = {
    subdomain    = aws_route53_zone.cluster.name
    name_servers = aws_route53_zone.cluster.name_servers
  }
}

# Data source used to grab the TLS certificate for Terraform Cloud.
#
# https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/certificate
data "tls_certificate" "tfc_certificate" {
  url = "https://${local.tfc_hostname}"
}

# Creates an OIDC provider which is restricted to
#
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider
resource "aws_iam_openid_connect_provider" "tfc_provider" {
  url             = data.tls_certificate.tfc_certificate.url
  client_id_list  = [local.tfc_aws_audience]
  thumbprint_list = [data.tls_certificate.tfc_certificate.certificates[0].sha1_fingerprint]
}

resource "tfe_project" "this" {
  organization = var.tf_org_name
  name         = var.tf_project_name
}

module "core_workspaces" {
  for_each = var.core_workspaces
  source   = "./modules/workspace"

  organization                     = var.tf_org_name
  aws_oidc_provider_arn            = aws_iam_openid_connect_provider.tfc_provider.arn
  aws_oidc_provider_client_id_list = aws_iam_openid_connect_provider.tfc_provider.client_id_list
  tfc_hostname                     = local.tfc_hostname
  project_name                     = tfe_project.this.name
  project_id                       = tfe_project.this.id

  name        = each.key
  env         = each.value.env
  dns_suffix  = aws_route53_zone.cluster.name
  description = each.value.description
  tags        = each.value.tags
}