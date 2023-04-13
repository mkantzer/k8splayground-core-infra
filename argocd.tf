# Deploys ArgoCD, initilizes top-level apps-of-apps, and passes in any needed values for consumption by sup-apps
module "argocd" {
  # given the lack of a release, and the up-in-the-airness of the system, i'm pinning a commit.
  source = "github.com/aws-ia/terraform-aws-eks-blueprints-addons//modules/argocd?ref=739dfd5"

  helm_config = {
    name             = "argo-cd"
    chart            = "argo-cd"
    repository       = "https://argoproj.github.io/argo-helm"
    version          = "5.28.1"
    namespace        = "argocd"
    timeout          = "1200"
    create_namespace = true
    values           = [templatefile("${path.module}/values-argocd.yaml", {})]
    set_sensitive = [
      {
        name  = "configs.secret.argocdServerAdminPassword"
        value = bcrypt_hash.argo.id
      }
    ]
  }

  # Will use later, if/when I want to actually play around with softish multitenancy
  # projects = {}
  applications = {
    addons = {
      path               = "addOns/${var.cluster_addons_version}/chart"
      repo_url           = "https://github.com/mkantzer/k8splayground-cluster-state.git"
      add_on_application = true
      values = {
        awsLoadBalancerController = {
          enable             = true
          serviceAccountName = local.aws_load_balancer_controller_service_account
          vpcId              = module.vpc.vpc_id
        }
        externalDNS = {
          enable = true
          serviceAccountName = local.external_dns_service_account
          domainFilter = aws_route53_zone.cluster.name
        }
      }
    }
  }

  addon_context = local.addon_context
  # NOT using this, because it would/could cause the merge() to override per-add-on values.
  # merge: https://github.com/aws-ia/terraform-aws-eks-blueprints-addons/blob/739dfd5/modules/argocd/main.tf#L68-L77
  # addon_config  = { for k, v in local.argocd_addon_config : k => v if v != null }
}

#---------------------------------------------------------------
# ArgoCD Admin Password credentials with Secrets Manager
# Login to AWS Secrets manager with the same role as Terraform to extract the ArgoCD admin password with the secret name as "argocd"
#---------------------------------------------------------------
resource "random_password" "argocd" {
  length           = 26
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Argo requires the password to be bcrypt, we use custom provider of bcrypt,
# as the default bcrypt function generates diff for each terraform plan
resource "bcrypt_hash" "argo" {
  cleartext = random_password.argocd.result
}

#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "argocd" {
  name                    = "${module.eks.cluster_name}/argocd"
  recovery_window_in_days = 0 # force delete during Terraform destroy
}

resource "aws_secretsmanager_secret_version" "argocd" {
  secret_id     = aws_secretsmanager_secret.argocd.id
  secret_string = random_password.argocd.result
}

locals {
  addon_context = {
    aws_caller_identity_account_id = local.account_id
    aws_caller_identity_arn        = data.aws_caller_identity.current.arn
    aws_partition_id               = local.partition
    aws_region_name                = local.region
    eks_cluster_id                 = module.eks.cluster_name
    aws_eks_cluster_endpoint       = module.eks.cluster_endpoint
    eks_oidc_issuer_url            = module.eks.oidc_provider
    eks_oidc_provider_arn          = module.eks.oidc_provider_arn
  }
}
