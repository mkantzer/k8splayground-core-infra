# Creates a role which can only be used by the specified Terraform
# cloud workspace.
resource "aws_iam_role" "tfc_role" {
  name = "tfc-${var.project_name}-${tfe_workspace.this.name}"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Effect": "Allow",
     "Principal": {
       "Federated": "${var.aws_oidc_provider_arn}"
     },
     "Action": "sts:AssumeRoleWithWebIdentity",
     "Condition": {
       "StringEquals": {
         "${var.tfc_hostname}:aud": "${one(var.aws_oidc_provider_client_id_list)}"
       },
       "StringLike": {
         "${var.tfc_hostname}:sub": "organization:${var.organization}:project:${var.project_name}:workspace:${tfe_workspace.this.name}:run_phase:*"
       }
     }
   }
 ]
}
EOF
}

# Creates a policy that will be used to define the permissions that
# the previously created role has within AWS.
resource "aws_iam_policy" "tfc_policy" {
  name        = "tfc-${var.project_name}-${tfe_workspace.this.name}"
  description = "TFC run policy for ${tfe_workspace.this.name} in ${var.project_name}"

  policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Effect": "Allow",
     "Action": [
       "*"
     ],
     "Resource": "*"
   }
 ]
}
EOF
}

# Creates an attachment to associate the above policy with the
# previously created role.
resource "aws_iam_role_policy_attachment" "tfc_policy_attachment" {
  role       = aws_iam_role.tfc_role.name
  policy_arn = aws_iam_policy.tfc_policy.arn
}