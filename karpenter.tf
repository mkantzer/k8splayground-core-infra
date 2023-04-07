# The actual karpenter _cluster_ component is managed in addons.tf

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 19.12"

  cluster_name           = module.eks.cluster_name

  irsa_oidc_provider_arn = module.eks.oidc_provider_arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]

  policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}

resource "kubectl_manifest" "karpenter_provisioner" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1alpha5
    kind: Provisioner
    metadata:
      name: default
    spec:
      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot"]
      limits:
        resources:
          cpu: 1000
      providerRef:
        name: bottlerocket
      ttlSecondsAfterEmpty: 30
  YAML

  depends_on = [
    module.k8s_bootstrap_addons
  ]
}

resource "kubectl_manifest" "karpenter_node_template" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1alpha1
    kind: AWSNodeTemplate
    metadata:
      name: bottlerocket
    spec:
      subnetSelector:
        karpenter.sh/discovery: ${module.eks.cluster_name}
      securityGroupSelector:
        karpenter.sh/discovery: ${module.eks.cluster_name}
      tags:
        karpenter.sh/discovery: ${module.eks.cluster_name}
      metadataOptions:
        httpEndpoint: enabled
        httpProtocolIPv6: enabled
        httpPutResponseHopLimit: 1
        httpTokens: required
      amiFamily: Bottlerocket
      blockDeviceMappings:
        # Root device
        - deviceName: /dev/xvda
          ebs:
            volumeSize: 4Gi
            volumeType: gp3
            encrypted: true
        # Data device: Container resources such as images and logs
        - deviceName: /dev/xvdb
          ebs:
            volumeSize: 20Gi
            volumeType: gp3
            encrypted: true
  YAML

  depends_on = [
    module.k8s_bootstrap_addons
  ]
}

# # Example deployment using the [pause image](https://www.ianlewis.org/en/almighty-pause-container)
# # and starts with zero replicas
# resource "kubectl_manifest" "karpenter_example_deployment" {
#   yaml_body = <<-YAML
#     apiVersion: apps/v1
#     kind: Deployment
#     metadata:
#       name: inflate
#     spec:
#       replicas: 0
#       selector:
#         matchLabels:
#           app: inflate
#       template:
#         metadata:
#           labels:
#             app: inflate
#         spec:
#           terminationGracePeriodSeconds: 0
#           containers:
#             - name: inflate
#               image: public.ecr.aws/eks-distro/kubernetes/pause:3.7
#               resources:
#                 requests:
#                   cpu: 1
#   YAML

#   depends_on = [
#     helm_release.karpenter
#   ]
# }