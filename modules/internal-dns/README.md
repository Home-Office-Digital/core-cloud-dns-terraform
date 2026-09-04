# internal-dns

Creates the internal (private) DNS for a workload account: a private hosted zone
(associated with the workload VPC) and a matching public hosted zone used for ACM
DNS validation, plus Route 53 Profile associations. Supports one primary
`internal_domain_name` and any number of `additional_internal_domain_names`.

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.63.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.9.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudwatch_log_group.additional_r53_log_groups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.additional_r53_log_groups_phz](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.r53_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.r53_log_group_phz](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_kms_key.additional_dnssec_keys](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key.dnssec_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key.r53_query_log_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_route53_hosted_zone_dnssec.additional_dnssec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_hosted_zone_dnssec) | resource |
| [aws_route53_hosted_zone_dnssec.dnssec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_hosted_zone_dnssec) | resource |
| [aws_route53_key_signing_key.additional_ksks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_key_signing_key) | resource |
| [aws_route53_key_signing_key.ksk](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_key_signing_key) | resource |
| [aws_route53_query_log.additional_r53_query_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_query_log) | resource |
| [aws_route53_query_log.additional_r53_query_logs_phz](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_query_log) | resource |
| [aws_route53_query_log.r53_query_log](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_query_log) | resource |
| [aws_route53_query_log.r53_query_log_phz](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_query_log) | resource |
| [aws_route53_zone.additional_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_route53_zone.additional_public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_route53_zone.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_route53_zone.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_route53profiles_association.vpc_to_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53profiles_association) | resource |
| [aws_route53profiles_resource_association.additional_phz_to_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53profiles_resource_association) | resource |
| [aws_route53profiles_resource_association.phz_to_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53profiles_resource_association) | resource |
| [random_id.additional_phz_assoc](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [random_id.phz_assoc](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_vpcs.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpcs) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_internal_domain_names"></a> [additional\_internal\_domain\_names](#input\_additional\_internal\_domain\_names) | Additional domain names used to create BOTH private and public hosted zones (e.g. np.internal.core.homeoffice.gov.uk). | `list(string)` | `[]` | no |
| <a name="input_enable_dnssec"></a> [enable\_dnssec](#input\_enable\_dnssec) | Enable Route53 DNSSEC signing | `bool` | `false` | no |
| <a name="input_enable_r53_query_logging"></a> [enable\_r53\_query\_logging](#input\_enable\_r53\_query\_logging) | Enable Route53 Query Logging | `bool` | `false` | no |
| <a name="input_internal_domain_name"></a> [internal\_domain\_name](#input\_internal\_domain\_name) | Single domain name used to create BOTH private and public hosted zones (e.g. np.internal.core.homeoffice.gov.uk). | `string` | n/a | yes |
| <a name="input_r53_query_logging_length"></a> [r53\_query\_logging\_length](#input\_r53\_query\_logging\_length) | Length in days to store route53 query logs. Must be a value supported by CloudWatch Logs retention. | `number` | `365` | no |
| <a name="input_route53_profile_id"></a> [route53\_profile\_id](#input\_route53\_profile\_id) | Route 53 Profile ID to associate the VPC and PHZ with. Pass via GitHub env var TF\_VAR\_route53\_profile\_id. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to created resources. | `map(string)` | `{}` | no |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | Value of the VPC 'Name' tag used to look up the VPC ID. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_additional_name_servers"></a> [additional\_name\_servers](#output\_additional\_name\_servers) | Map of additional internal domain name => that public zone's name servers (used for delegation). |
| <a name="output_additional_zone_ids"></a> [additional\_zone\_ids](#output\_additional\_zone\_ids) | Map of additional internal domain name => its public hosted zone ID (used for ACM DNS validation). |
| <a name="output_name_servers"></a> [name\_servers](#output\_name\_servers) | List of name servers for delegation |
| <a name="output_zone_id"></a> [zone\_id](#output\_zone\_id) | The ID of the Route 53 hosted zone |
<!-- END_TF_DOCS -->
