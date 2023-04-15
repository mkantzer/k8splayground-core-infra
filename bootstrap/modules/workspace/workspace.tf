resource "tfe_workspace" "this" {
  organization = var.organization
  project_id   = var.project_id

  name           = var.name
  execution_mode = "remote"

  tag_names = concat(
    [
      "project:${var.project_name}"
    ],
    var.tags
  )
}

# Used to set workspace to automatically use `environments/${env}.tfvars
resource "tfe_variable" "env" {
  workspace_id = tfe_workspace.this.id

  key      = "env"
  value    = var.env
  category = "terraform"
}

resource "tfe_variable" "dns_suffix" {
  workspace_id = tfe_workspace.this.id

  key      = "dns_suffix"
  value    = var.dns_suffix
  category = "terraform"
}

# Used to set workspace to automatically use `environments/${env}.tfvars
resource "tfe_variable" "cli_args" {
  workspace_id = tfe_workspace.this.id

  key      = "TF_CLI_ARGS_plan"
  value    = "-var-file=environment/${var.env}.tfvars"
  category = "env"

  description = "Sets workspace to automatically consume the correct .tfvars file."
}


# The following variables must be set to allow runs
# to authenticate to AWS.
#
# https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/variable
resource "tfe_variable" "enable_aws_provider_auth" {
  workspace_id = tfe_workspace.this.id

  key      = "TFC_AWS_PROVIDER_AUTH"
  value    = "true"
  category = "env"

  description = "Enable the Workload Identity integration for AWS."
}

resource "tfe_variable" "tfc_aws_role_arn" {
  workspace_id = tfe_workspace.this.id

  key      = "TFC_AWS_RUN_ROLE_ARN"
  value    = aws_iam_role.tfc_role.arn
  category = "env"

  description = "The AWS role arn runs will use to authenticate."
}