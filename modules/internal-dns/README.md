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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.62.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.9.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_route53_zone.additional_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_route53_zone.additional_public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_route53_zone.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_route53_zone.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_route53profiles_association.vpc_to_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53profiles_association) | resource |
| [aws_route53profiles_resource_association.additional_phz_to_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53profiles_resource_association) | resource |
| [aws_route53profiles_resource_association.phz_to_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53profiles_resource_association) | resource |
| [random_id.additional_phz_assoc](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [random_id.phz_assoc](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [aws_vpcs.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpcs) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_internal_domain_names"></a> [additional\_internal\_domain\_names](#input\_additional\_internal\_domain\_names) | Additional domain names used to create BOTH private and public hosted zones (e.g. np.internal.core.homeoffice.gov.uk). | `list(string)` | `[]` | no |
| <a name="input_internal_domain_name"></a> [internal\_domain\_name](#input\_internal\_domain\_name) | Single domain name used to create BOTH private and public hosted zones (e.g. np.internal.core.homeoffice.gov.uk). | `string` | n/a | yes |
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
