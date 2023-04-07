module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.12"

  cluster_name                   = "playground-${var.env}"
  cluster_version                = var.cluster_version
  cluster_endpoint_public_access = true

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  # Fargate profiles use the cluster primary security group so these are not utilized
  create_cluster_security_group = false
  create_node_security_group    = false

  manage_aws_auth_configmap = true
  aws_auth_roles = [{
    # We need to add in the Karpenter node IAM role for nodes launched by Karpenter
    rolearn  = module.karpenter.role_arn
    username = "system:node:{{EC2PrivateDNSName}}"
    groups = [
      "system:bootstrappers",
      "system:nodes",
    ]
  }]
  aws_auth_users = [{
    userarn  = "arn:aws:iam::537161898135:user/Mike"
    username = "admin"
    groups   = ["system:master"]
  }]

  fargate_profiles = {
    karpenter = {
      selectors = [
        { namespace = "karpenter" }
      ]
    }
    kube-system = {
      selectors = [
        { namespace = "kube-system" }
      ]
    }
  }

  cluster_addons = {
    coredns = {
      configuration_values = jsonencode({
        computeType = "Fargate"
        # Resources set to properly utilize Fargate. See:
        # https://github.com/terraform-aws-modules/terraform-aws-eks/blob/v19.12.0/examples/karpenter/main.tf#L85
        # for an explanation
        resources = {
          limits = {
            cpu    = "0.25"
            memory = "256M"
          }
          requests = {
            cpu    = "0.25"
            memory = "256M"
          }
        }
      })
    }
    kube-proxy = {}
    vpc-cni = {
      most_recent    = true
      before_compute = true
      configuration_values = jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }
}








# module "eks_blueprints" {
#   source = "git@github.com:aws-ia/terraform-aws-eks-blueprints.git?ref=v4.27.0"

#   cluster_name    = local.name
#   cluster_version = var.cluster_version

#   vpc_id             = module.vpc.vpc_id
#   private_subnet_ids = module.vpc.private_subnets

#   create_cloudwatch_log_group            = true
#   cluster_enabled_log_types              = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
#   cloudwatch_log_group_retention_in_days = 10

#   create_iam_role              = true
#   iam_role_additional_policies = []
#   enable_irsa                  = true

#   map_roles = []
#   map_users = [{
#     userarn  = "arn:aws:iam::537161898135:user/Mike"
#     username = "admin"
#     groups   = ["system:master"]

#   }]


#   managed_node_groups = {
#     bottlerocket_x86 = {
#       # 1> Node Group configuration - Part1
#       node_group_name        = "btl-x86"      # Max 40 characters for node group name
#       create_launch_template = true           # false will use the default launch template
#       launch_template_os     = "bottlerocket" # amazonlinux2eks or bottlerocket
#       public_ip              = false          # Use this to enable public IP for EC2 instances; only for public subnets used in launch templates ;
#       # 2> Node Group scaling configuration
#       desired_size    = 2
#       max_size        = 2
#       min_size        = 2
#       max_unavailable = 1 # or percentage = 20

#       # 3> Node Group compute configuration
#       ami_type       = "BOTTLEROCKET_x86_64" # AL2_x86_64, AL2_x86_64_GPU, AL2_ARM_64, CUSTOM, BOTTLEROCKET_ARM_64, BOTTLEROCKET_x86_64
#       capacity_type  = "ON_DEMAND"           # ON_DEMAND or SPOT
#       instance_types = ["m5.large"]          # List of instances used only for SPOT type
#       block_device_mappings = [
#         {
#           device_name = "/dev/xvda"
#           volume_type = "gp3"
#           volume_size = 100
#         }
#       ]
#       k8s_taints = []
#       k8s_labels = {
#         Environment = "preprod"
#         Node_OS     = "bottlerocket"
#         Node_Arch   = "x86_64"
#         Zone        = var.env
#         WorkerType  = "ON_DEMAND"
#       }
#       additional_tags = {
#         ExtraTag    = "m5x-on-demand"
#         Name        = "m5x-on-demand"
#         subnet_type = "private"
#       }
#     },
#   }

#   node_security_group_additional_rules = {
#     # Extend node-to-node security group rules. Recommended and required for the Add-ons
#     ingress_self_all = {
#       description = "Node to node all ports/protocols"
#       protocol    = "-1"
#       from_port   = 0
#       to_port     = 0
#       type        = "ingress"
#       self        = true
#     }
#     # Recommended outbound traffic for Node groups
#     egress_all = {
#       description      = "Node all egress"
#       protocol         = "-1"
#       from_port        = 0
#       to_port          = 0
#       type             = "egress"
#       cidr_blocks      = ["0.0.0.0/0"]
#       ipv6_cidr_blocks = ["::/0"]
#     }
#     # Allows Control Plane Nodes to talk to Worker nodes on all ports. Added this to simplify the example and further avoid issues with Add-ons communication with Control plane.
#     # This can be restricted further to specific port based on the requirement for each Add-on e.g., metrics-server 4443, spark-operator 8080, karpenter 8443 etc.
#     # Change this according to your security requirements if needed
#     ingress_cluster_to_node_all_traffic = {
#       description                   = "Cluster API to Nodegroup all traffic"
#       protocol                      = "-1"
#       from_port                     = 0
#       to_port                       = 0
#       type                          = "ingress"
#       source_cluster_security_group = true
#     }
#   }

#   # TODO: create and run "must-execute" components here.
#   fargate_profile {}
# }