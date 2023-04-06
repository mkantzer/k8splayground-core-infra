tf_project_name = "k8s-playground"
core_workspaces = {
  cluster-dev = {
    env         = "dev"
    description = "Primary configuration for development cluster"
    tags = [
      "core-infra",
      "cluster",
      "dev",
    ]
  },
}
