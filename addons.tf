# We have _2_ instances of the addons module. This allows us to split out the components that we _do not_ want managed 
# by argoCD, because they need to be in place before argo comes online.

# Addons required to bootstrap ArgoCD
module "k8s_bootstrap_addons" {
  # given the lack of a release, and the up-in-the-airness of the system, i'm pinning a commit.
  source = "github.com/aws-ia/terraform-aws-eks-blueprints-addons?ref=3e64d80"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider     = module.eks.oidc_provider
  oidc_provider_arn = module.eks.oidc_provider_arn

  enable_karpenter = true
  karpenter_helm_config = {
    repository_username = data.aws_ecrpublic_authorization_token.token.user_name
    repository_password = data.aws_ecrpublic_authorization_token.token.password
  }
  karpenter_node_iam_instance_profile        = module.karpenter.instance_profile_name
  karpenter_enable_spot_termination_handling = true
}