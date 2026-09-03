# internal-dns-cert

Requests wildcard ACM certificates for internal domains and validates them via DNS
records in the corresponding public hosted zone. Handles the primary
`internal_domain_name` (validated in `internal_zone_id`) and any
`additional_internal_zone_ids` (a map of domain to its public hosted zone ID,
sourced from the internal-dns module's `additional_zone_ids` output).

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.62.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_acm_certificate.additional_wildcards](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate.wildcard](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate_validation.additional_wildcards](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) | resource |
| [aws_acm_certificate_validation.wildcard](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) | resource |
| [aws_route53_record.additional_wildcard_validations](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.wildcard_validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_internal_zone_ids"></a> [additional\_internal\_zone\_ids](#input\_additional\_internal\_zone\_ids) | A map of corresponding zone IDs with domain as the key | `map(string)` | `{}` | no |
| <a name="input_internal_domain_name"></a> [internal\_domain\_name](#input\_internal\_domain\_name) | Single domain name used to create BOTH private and public hosted zones (e.g. np.internal.core.homeoffice.gov.uk). | `string` | n/a | yes |
| <a name="input_internal_zone_id"></a> [internal\_zone\_id](#input\_internal\_zone\_id) | n/a | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to created resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_wildcard_certificate_arn"></a> [wildcard\_certificate\_arn](#output\_wildcard\_certificate\_arn) | Wildcard ACM certificate ARN. |
<!-- END_TF_DOCS -->
