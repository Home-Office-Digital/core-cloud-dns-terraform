<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_kms_key.additional_dnssec_keys](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key.dnssec_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_route53_hosted_zone_dnssec.additional_dnssec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_hosted_zone_dnssec) | resource |
| [aws_route53_hosted_zone_dnssec.dnssec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_hosted_zone_dnssec) | resource |
| [aws_route53_key_signing_key.additional_ksks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_key_signing_key) | resource |
| [aws_route53_key_signing_key.ksk](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_key_signing_key) | resource |
| [aws_route53_zone.additional_workload_zones](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_route53_zone.workload_zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_domain_names"></a> [additional\_domain\_names](#input\_additional\_domain\_names) | A list of additional Route 53 hosted zones | `list(string)` | `[]` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | The domain name for the Route 53 hosted zone | `string` | n/a | yes |
| <a name="input_enable_dnssec"></a> [enable\_dnssec](#input\_enable\_dnssec) | Enable Route53 DNSSEC signing | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The environment in which the hosted zone is deployed | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to be applied to the hosted zone | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_additional_dnssec_ds_record"></a> [additional\_dnssec\_ds\_record](#output\_additional\_dnssec\_ds\_record) | Map of additional domain name => DS record for the registrar, when DNSSEC is enabled (null otherwise). |
| <a name="output_additional_name_servers"></a> [additional\_name\_servers](#output\_additional\_name\_servers) | Map of additional domain name => that zone's name servers (used for delegation). |
| <a name="output_additional_zone_ids"></a> [additional\_zone\_ids](#output\_additional\_zone\_ids) | Map of additional domain name => its public hosted zone ID. |
| <a name="output_dnssec_ds_record"></a> [dnssec\_ds\_record](#output\_dnssec\_ds\_record) | DS record to add at your domain registrar when DNSSEC is enabled |
| <a name="output_name_servers"></a> [name\_servers](#output\_name\_servers) | List of name servers for delegation |
| <a name="output_zone_id"></a> [zone\_id](#output\_zone\_id) | The ID of the Route 53 hosted zone |
<!-- END_TF_DOCS -->