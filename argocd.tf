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
    # values           = [templatefile("${path.module}/values-argocd.yaml", {})]
    values = [yamlencode({
      # Ingress: currently disabled, because I don't actually want anyone hitting argocd's API
      # server = {
      #   ingress = {
      #     enabled          = true
      #     ingressClassName = "alb"
      #     annotations = {
      #       "alb.ingress.kubernetes.io/scheme"       = "internet-facing"
      #       "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTPS\":443}]"
      #       "alb.ingress.kubernetes.io/target-type"  = "ip"
      #     }
      #     hosts = ["argocd.${aws_route53_zone.cluster.name}"]
      #     tls   = [{ hosts = ["argocd.${aws_route53_zone.cluster.name}"] }]
      #   }
      #   ingressGrpc = {
      #     enabled          = true
      #     isAWSALB         = true
      #     ingressClassName = "alb"
      #     annotations = {
      #       "alb.ingress.kubernetes.io/scheme"       = "internet-facing"
      #       "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTPS\":443}]"
      #       "alb.ingress.kubernetes.io/target-type"  = "ip"
      #     }
      #     hosts = ["argocd.${aws_route53_zone.cluster.name}"]
      #     tls   = [{ hosts = ["argocd.${aws_route53_zone.cluster.name}"] }]
      #   }
      # }

      # ArgoCD Cuelang Plugin
      configs = {
        cmp = {
          create = true
          plugins = {
            cuelang = {
              generate = {
                command = ["cue"]
                args    = ["cmd", "dump", "./..."]
              }
              discover = {
                find = {
                  glob = "**/*.cue"
      } } } } } }
      # Plugin Sidecar
      repoServer = {
        extraContainers = [{
          name    = "cmp-cuelang"
          command = ["/var/run/argocd/argocd-cmp-server"]
          image   = "ghcr.io/mkantzer/k8splayground-argocd-cuelang:1.0.0"
          securityContext = {
            runAsNonRoot = true
            runAsUser    = 999
          }
          volumeMounts = [{
            mountPath = "/var/run/argocd"
            name      = "var-files"
            }, {
            mountPath = "/home/argocd/cmp-server/plugins"
            name      = "plugins"
            }, {
            mountPath = "home/argocd/cmp-server/config/plugin.yaml"
            subPath   = "cuelang.yaml"
            name      = "argocd-cmp-cm"
            }, {
            mountPath = "/tmp"
            name      = "cmp-tmp"
        }] }],
        volumes = [{
          name      = "argocd-cmp-cm"
          configMap = { name = "argocd-cmp-cm" }
          }, {
          name     = "cmp-tmp"
          emptyDir = {}
        }]
    } })]
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
          enable = true
          serviceAccount = {
            create = true
            name   = local.aws_load_balancer_controller_service_account
            annotations = {
              "eks.amazonaws.com/role-arn" = module.aws_load_balancer_controller.iam_role_arn
            }
          }
          vpcId = module.vpc.vpc_id
        }
        externalDns = {
          enable = true
          serviceAccount = {
            create = true
            name   = local.external_dns_service_account
            annotations = {
              "eks.amazonaws.com/role-arn" = module.external_dns.iam_role_arn
            }
          }
          domainFilters = [
            aws_route53_zone.cluster.name
          ]
        }
      }
    }
    # echo-app = {
    #   path     = "k8s_apps/echo/dev"
    #   repo_url = "https://github.com/mkantzer/k8splayground-cluster-state.git"
    # }
  }

  addon_context = local.addon_context
  # NOT using this, because it would/could cause the merge() to override per-add-on values.
  # merge: https://github.com/aws-ia/terraform-aws-eks-blueprints-addons/blob/739dfd5/modules/argocd/main.tf#L68-L77
  # addon_config  = { for k, v in local.argocd_addon_config : k => v if v != null }
}


#---------------------------------------------------------------
# ArgoCD Cuelang App Bootstrap
# The argocd module can only create applications that explicitly use `helm` or `kustomize`.
# Tracking ticket: https://github.com/aws-ia/terraform-aws-eks-blueprints-addons/issues/127
# Therefor, we need to manually create any applications that we want to explicitly use `cue`
#---------------------------------------------------------------

# Note: right now, this is only being used to bootstrap a single app. 
# Once it is proven to work, (and once ingress is confirmed working),
# we will tranisition this to an app-of-apps (or, more likely, an ApplicationSet)
resource "kubectl_manifest" "argocd_cuelang_app" {
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "echo"
      namespace = "argocd"
      finaliers = [
        "resources-finalizer.argocd.argoproj.io"
      ]
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/mkantzer/k8splayground-cluster-state.git"
        targetRevision = "HEAD"
        path           = "k8s_apps/echo/dev"
        plugin         = { name = "cuelang" }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "echo"
      }
      syncPolicy = {
        automated = {
          allowEmpty = false
          prune      = true
          selfHeal   = true
        }
        retry = {
          limit = 10
          backoff = {
            factor      = 2
            duration    = "10s"
            maxDuration = "3m"
          }
        }
        syncOptions = [
          "Validate=false",
          "CreateNamespace=true",
          "PrunePropagationPolicy=foreground",
          "PruneLast=true",
          "RespectIgnoreDifferences=true",
        ]
      }
    }
  })

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
