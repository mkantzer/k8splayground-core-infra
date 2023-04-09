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

Given the changes to eks blueprints, managing add-ons is in a bit of a weird state. In general, the changes appears to be directed at: 
- creating a [new reference repo](https://github.com/aws-ia/terraform-aws-eks-blueprints-addons)
- changing the organization and style of add-on modules: instead of each add-on requiring a full module _in the repo_, most add-ons will be converted to use a generalized [eks-blueprints-addon](https://github.com/aws-ia/terraform-aws-eks-blueprints-addons/tree/485133f/modules/eks-blueprints-addon) module, that handles provisioning of IRSA and (potentially) a helm-chart.
  - note: the link above is to a _temporary_ copy of the module, while the long-term repo and registry entry are vetted for release. Long term links (that should eventually become live) are below:
  - [terraform module registry](https://registry.terraform.io/modules/aws-ia/eks-blueprints-addon/aws)
  - [github repo](https://github.com/aws-ia/terraform-aws-kubernetes-addon/)

Because the repos _are not_ ready, are in pretty constant flux _and_ are [buggy in fundamental ways](https://github.com/aws-ia/terraform-aws-eks-blueprints-addons/issues/104), I'm taking the following approach (as of this writing. Likely will change. I'll try to keep this section updated):
- When consuming a module sourced from any of these systems, will pin a version/commit, not a branch.
- Will try to keep up-to-date with the modules, and simplify the below when possible.
- Avoid using the _root_ module at [terraform-aws-eks-blueprints-addons](https://github.com/aws-ia/terraform-aws-eks-blueprints-addons), but will instead use it as a _reference_. (Might change if my bug gets resolved?)
- Continue using the [blueprint ArgoCD module](https://github.com/aws-ia/terraform-aws-eks-blueprints-addons/tree/65f6432/modules/argocd): it's well-abstracted, and gives the needed toggles.
- Will use the [eks-blueprints-addon](https://github.com/aws-ia/terraform-aws-eks-blueprints-addons/tree/65f6432/modules/eks-blueprints-addon) module for bootstrapping IRSA: it's well-abstracted, and designed to be used with the argocd module.
  - Will _only_ use it to manage IRSA, and pass values into argoCD. Will _not_ use it to render the helm release, because that's argo's job.
- Each add-on will get a top-level `<addonName>.tf` file here, that will contain its policy document and use of the add-on module.


### A note on karpenter:

Our basic goal is to have as much of our system git-ops'd as possible. However, karpenter-in-fargate is the only system that actual creates nodes, so it needs to be fully ready _before_ argoCD comes online. Therefor, we directly deploy karpenter's helmchart and configuration outside of the normal scope of argocd.