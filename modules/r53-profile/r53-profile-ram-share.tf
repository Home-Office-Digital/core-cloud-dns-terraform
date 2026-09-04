resource "aws_ram_resource_share" "cc_r53_profile_share" {
  name                      = "Network-Account-R53-Shared-Profile"
  allow_external_principals = false
  permission_arns           = var.r53_ram_share_permission_arns
}

# Share with AWS Organization
resource "aws_ram_principal_association" "cc_org_association" {
  principal          = var.cc_aws_orgnisation_arn
  resource_share_arn = aws_ram_resource_share.cc_r53_profile_share.arn
}

# Associate Route53 Profile to Resource Share
resource "aws_ram_resource_association" "r53_association" {
  resource_arn       = aws_route53profiles_profile.cc_r53_profile.arn
  resource_share_arn = aws_ram_resource_share.cc_r53_profile_share.arn
}

# Optionally, share with specific AWS Accounts
# Uncomment if needed
# resource "aws_ram_principal_association" "cc_accounts_association" {
#   principal          = var.core_cloud_accounts
#   resource_share_arn = aws_ram_resource_share.cc_r53_profile_share.arn
# }
