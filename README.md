# k8splayground-core-infra

Handles terraform for core infra of Kubernetes playground: Networking, clusters, etc.

Primarily driven by EKS Blueprints:
- [repo](https://github.com/aws-ia/terraform-aws-eks-blueprints)
- [docs](https://aws-ia.github.io/terraform-aws-eks-blueprints/)

However, given the [change in direction for v5 of blueprints](https://github.com/aws-ia/terraform-aws-eks-blueprints/blob/docs/v5-direction/DIRECTION_v5.md), I will _not_ be adopting the actual root blueprint module. Instead, I will be consuming the examples as references.

## Architecture and properties:
- [Karpenter running on Fargate](https://github.com/terraform-aws-modules/terraform-aws-eks/tree/v19.12.0/examples/karpenter), managing the provisioning of node groups
- 