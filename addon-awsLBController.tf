locals {
  aws_load_balancer_controller = {
    name            = "aws-load-balancer-controller"
    service_account = "${local.aws_load_balancer_controller.name}-sa"
  }
}

module "aws_load_balancer_controller" {
  # source = "aws-ia/eks-blueprints-addon/aws"
  # version = "1.0.0"
  # given the lack of a release, and the up-in-the-airness of the system, i'm pinning a commit.
  source = "github.com/aws-ia/terraform-aws-eks-blueprints-addons//modules/eks-blueprints-addon?ref=739dfd5"

  create         = true
  create_release = false

  # IAM role for service account (IRSA)
  create_role          = true
  set_irsa_name        = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
  role_name            = "alb-controller"
  role_name_use_prefix = true
  role_path            = "/"
  # role_permissions_boundary_arn = lookup(var.aws_load_balancer_controller, "role_permissions_boundary_arn", null)
  role_description = "IRSA for aws-load-balancer-controller, ${module.eks.cluster_name}"
  # role_policies                 = lookup(var.aws_load_balancer_controller, "role_policies", {})

  source_policy_documents = compact(concat(
    data.aws_iam_policy_document.aws_load_balancer_controller[*].json,
    # lookup(var.aws_load_balancer_controller, "source_policy_documents", [])
  ))
  # override_policy_documents = lookup(var.aws_load_balancer_controller, "override_policy_documents", [])
  # policy_statements         = lookup(var.aws_load_balancer_controller, "policy_statements", [])
  # policy_name               = try(var.aws_load_balancer_controller.policy_name, null)
  # policy_name_use_prefix    = try(var.aws_load_balancer_controller.policy_name_use_prefix, true)
  # policy_path               = try(var.aws_load_balancer_controller.policy_path, null)
  policy_description = "IAM Policy for AWS Load Balancer Controller, ${module.eks.cluster_name}"

  oidc_providers = {
    this = {
      provider_arn = module.eks.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.aws_load_balancer_controller.service_account
    }
  }
}

data "aws_iam_policy_document" "aws_load_balancer_controller" {
  statement {
    resources = ["*"]
    actions   = ["iam:CreateServiceLinkedRole"]

    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values   = ["elasticloadbalancing.amazonaws.com"]
    }
  }

  statement {
    resources = ["*"]

    actions = [
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeCoipPools",
      "ec2:DescribeInstances",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVpcPeeringConnections",
      "ec2:DescribeVpcs",
      "ec2:GetCoipPoolUsage",
      "elasticloadbalancing:DescribeListenerCertificates",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeSSLPolicies",
      "elasticloadbalancing:DescribeTags",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetHealth",
    ]
  }

  statement {
    resources = ["*"]

    actions = [
      "acm:DescribeCertificate",
      "acm:ListCertificates",
      "cognito-idp:DescribeUserPoolClient",
      "iam:GetServerCertificate",
      "iam:ListServerCertificates",
      "shield:CreateProtection",
      "shield:DeleteProtection",
      "shield:DescribeProtection",
      "shield:GetSubscriptionState",
      "waf-regional:AssociateWebACL",
      "waf-regional:DisassociateWebACL",
      "waf-regional:GetWebACL",
      "waf-regional:GetWebACLForResource",
      "wafv2:AssociateWebACL",
      "wafv2:DisassociateWebACL",
      "wafv2:GetWebACL",
      "wafv2:GetWebACLForResource",
    ]
  }

  statement {
    resources = ["*"]

    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
    ]
  }

  statement {
    resources = ["*"]

    actions = ["ec2:CreateSecurityGroup"]
  }

  statement {
    resources = ["arn:${local.partition}:ec2:*:*:security-group/*"]

    actions = ["ec2:CreateTags"]

    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }

    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values   = ["CreateSecurityGroup"]
    }
  }

  statement {
    resources = ["arn:${local.partition}:ec2:*:*:security-group/*"]

    actions = [
      "ec2:CreateTags",
      "ec2:DeleteTags",
    ]

    condition {
      test     = "Null"
      variable = "aws:ResourceTag/ingress.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    resources = [
      "arn:${local.partition}:elasticloadbalancing:*:*:loadbalancer/app/*/*",
      "arn:${local.partition}:elasticloadbalancing:*:*:loadbalancer/net/*/*",
      "arn:${local.partition}:elasticloadbalancing:*:*:targetgroup/*/*",
    ]

    actions = [
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:RemoveTags",
    ]

    condition {
      test     = "Null"
      variable = "aws:ResourceTag/ingress.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    resources = ["arn:${local.partition}:ec2:*:*:security-group/*"]

    actions = [
      "ec2:CreateTags",
      "ec2:DeleteTags",
    ]

    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }

    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values   = ["true"]
    }
  }

  statement {
    resources = ["*"]

    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:DeleteSecurityGroup",
      "ec2:RevokeSecurityGroupIngress",
    ]

    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    resources = ["*"]

    actions = [
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateTargetGroup",
    ]

    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    resources = ["*"]

    actions = [
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:CreateRule",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:DeleteRule",
    ]
  }

  statement {
    resources = [
      "arn:${local.partition}:elasticloadbalancing:*:*:loadbalancer/app/*/*",
      "arn:${local.partition}:elasticloadbalancing:*:*:loadbalancer/net/*/*",
      "arn:${local.partition}:elasticloadbalancing:*:*:targetgroup/*/*",
    ]

    actions = [
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:RemoveTags",
    ]

    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values   = ["true"]
    }

    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    resources = [
      "arn:${local.partition}:elasticloadbalancing:*:*:listener/net/*/*/*",
      "arn:${local.partition}:elasticloadbalancing:*:*:listener/app/*/*/*",
      "arn:${local.partition}:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
      "arn:${local.partition}:elasticloadbalancing:*:*:listener-rule/app/*/*/*",
    ]

    actions = [
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:RemoveTags",
    ]
  }

  statement {
    resources = ["*"]

    actions = [
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:SetIpAddressType",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets",
    ]

    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    resources = ["arn:${local.partition}:elasticloadbalancing:*:*:targetgroup/*/*"]

    actions = [
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:RegisterTargets",
    ]
  }

  statement {
    resources = ["*"]

    actions = [
      "elasticloadbalancing:AddListenerCertificates",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyRule",
      "elasticloadbalancing:RemoveListenerCertificates",
      "elasticloadbalancing:SetWebAcl",
    ]
  }
}