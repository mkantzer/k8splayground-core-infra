# Deploys ArgoCD, initilizes top-level apps-of-apps, and generates AWS resources for any enabled add-on
module "k8s_addons" {
  # given the lack of a release, and the up-in-the-airness of the system, i'm pinning a commit.
  source = "github.com/aws-ia/terraform-aws-eks-blueprints-addons?ref=3e64d80"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider     = module.eks.oidc_provider
  oidc_provider_arn = module.eks.oidc_provider_arn

  enable_argocd = true
  # Set default ArgoCD Admin Password using SecretsManager with Helm Chart set_sensitive values.
  argocd_helm_config = {
    name             = "argo-cd"
    chart            = "argo-cd"
    repository       = "https://argoproj.github.io/argo-helm"
    version          = "5.28.1"
    namespace        = "argocd"
    timeout          = "1200"
    create_namespace = true
    values           = [templatefile("${path.module}/argocd-values.yaml", {})]
    set_sensitive = [
      {
        name  = "configs.secret.argocdServerAdminPassword"
        value = bcrypt_hash.argo.id
      }
    ]
  }

  # ArgoCD is responsible for managing/deploying the cluster part of add-ons.
  # This flag instructs terraform to only deploy the _aws_ components.
  argocd_manage_add_ons = true

  argocd_applications = {
    addons = {
      path               = "addOns/${var.cluster_addons_version}/chart"
      repo_url           = "https://github.com/mkantzer/k8splayground-cluster-state.git"
      add_on_application = true
    }
    # workloads = {
    #   path               = "envs/dev"
    #   repo_url           = "https://github.com/aws-samples/eks-blueprints-workloads.git"
    #   add_on_application = false
    # }
  }

  # # Add-ons
  # enable_aws_for_fluentbit             = true
  # # Let fluentbit create the cw log group
  # aws_for_fluentbit_create_cw_log_group = false
  # enable_metrics_server                 = true
  # enable_prometheus                     = true
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