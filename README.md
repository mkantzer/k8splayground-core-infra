# k8splayground-core-infra

Handles terraform for core infra of Kubernetes playground: Networking, clusters, etc.

Primarily driven by EKS Blueprints:
- [repo](https://github.com/aws-ia/terraform-aws-eks-blueprints)
- [docs](https://aws-ia.github.io/terraform-aws-eks-blueprints/)

However, given the [change in direction for v5 of blueprints](https://github.com/aws-ia/terraform-aws-eks-blueprints/blob/docs/v5-direction/DIRECTION_v5.md), I will _not_ be adopting the actual root blueprint module. Instead, I will be consuming the examples as references.

## Architecture and properties:
- [Karpenter running on Fargate](https://github.com/terraform-aws-modules/terraform-aws-eks/tree/v19.12.0/examples/karpenter), managing the provisioning of node groups. Running in fargate protects against the failure mode of "no nodes, so can't run the controller that adds nodes".
- coredns, kube-proxy, vpc-cni, as required networking plugins, configured to support karpenter's initialization.
- fargate profiles for kube-system and karpenter .
- ArgoCD, for deploying everything else.


## Cluster Add-on Management:

Given the changes to eks blueprints, managing add-ons is in a bit of a weird state. I'm _pretty_ sure the goal is to just move them into [their own repo](https://github.com/aws-ia/terraform-aws-eks-blueprints-addons), which means I _should_ be able to just use the existing v4 examples, but pointed at the new repo. That's certainly what I'm going to _try_ to do.

- One for bootstrapping karpenter and anything else required to get the cluster ready for ArgoCD
- One for deploying ArgoCD to the cluster, initializing the apps-of-apps, and deploying any _aws_ resources required for a given add-on to function properly.

Our basic goal is to have as much of our system git-ops'd as possible. However, karpenter-in-fargate is the only system that actual creates nodes, so it needs to be fully ready _before_ argoCD comes online. Therefor, we directly deploy karpenter's helmchart and configuration outside of the normal scope of argocd.

To have the rest of the applications be managed by argocd, we use the module's `argocd_manage_add_ons` variable. This instructs terraform to only create the _aws_ resources for any enabled modules: the rest will be deployed via an argocd app-of-apps, which we store in the cluster-state repo, and structure generally like [aws's example](https://github.com/aws-samples/eks-blueprints-add-ons).

