# k8splayground-core-infra

Handles terraform for core infra of Kubernetes playground: Networking, clusters, etc.

Primarily driven by EKS Blueprints:
- [repo](https://github.com/aws-ia/terraform-aws-eks-blueprints)
- [docs](https://aws-ia.github.io/terraform-aws-eks-blueprints/)

However, given the [change in direction for v5 of blueprints](https://github.com/aws-ia/terraform-aws-eks-blueprints/blob/docs/v5-direction/DIRECTION_v5.md), I will _not_ be adopting the actual root blueprint module. Instead, I will be consuming the examples as references.

## Architecture and properties:
- [Karpenter running on Fargate](https://github.com/terraform-aws-modules/terraform-aws-eks/tree/v19.12.0/examples/karpenter), managing the provisioning of node groups. Running in fargate protects against the failure mode of "no nodes, so can't run the controller that adds nodes"
- coredns, kube-proxy, vpc-cni, as required networking plugins, configured to support karpenter's initialization
- fargate profiles for kube-system and karpenter 
- TODO: ArgoCD, for getting _basically_ everything else running




## Cluster Addon Management:

Given the changes to eks blueprints, managing addons is in a bit of a weird state. I'm _pretty_ sure the goal is to just move them into [their own repo](https://github.com/aws-ia/terraform-aws-eks-blueprints-addons), which means I _should_ be able to just use the existing v4 examples, but pointed at the new repo. That's certainly what I'm going to _try_ to do.