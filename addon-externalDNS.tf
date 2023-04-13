locals {
  external_dns_service_account = "external-dns-sa"
}

module "external_dns" {
  # source = "aws-ia/eks-blueprints-addon/aws"
  # version = "1.0.0"
  # given the lack of a release, and the up-in-the-airness of the system, i'm pinning a commit.
  source         = "github.com/aws-ia/terraform-aws-eks-blueprints-addons//modules/eks-blueprints-addon?ref=739dfd5"
  create         = true
  create_release = false

  # IAM role for service account (IRSA)
  create_role          = true
  set_irsa_name        = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
  role_name            = "external-dns"
  role_name_use_prefix = true
  role_path            = "/"
  # role_permissions_boundary_arn = lookup(var.external_dns, "role_permissions_boundary_arn", null)
  role_description = "IRSA for external-dns operator"
  # role_policies                 = lookup(var.external_dns, "role_policies", {})

  source_policy_documents = compact(concat(
    data.aws_iam_policy_document.external_dns.json,
    # lookup(var.external_dns, "source_policy_documents", [])
  ))
  # override_policy_documents = lookup(var.external_dns, "override_policy_documents", [])
  # policy_statements         = lookup(var.external_dns, "policy_statements", [])
  # policy_name               = try(var.external_dns.policy_name, null)
  # policy_name_use_prefix    = try(var.external_dns.policy_name_use_prefix, true)
  # policy_path               = try(var.external_dns.policy_path, null)
  policy_description = "IAM Policy for external-dns operator"

  oidc_providers = {
    this = {
      provider_arn = module.eks.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.external_dns_service_account
    }
  }
}

data "aws_iam_policy_document" "external_dns" {

  statement {
    actions = ["route53:ChangeResourceRecordSets"]
    resources = [
      aws_route53_zone.cluster.arn,
    ]
  }

  statement {
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
    ]
    resources = ["*"]
  }
}
