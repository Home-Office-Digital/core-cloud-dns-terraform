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
| [aws_route53_record.additional_ns_records](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.ns_record](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_name_servers"></a> [additional\_name\_servers](#input\_additional\_name\_servers) | Map of additional child domain name => that domain's own NS records (list), sourced from the r53-public-zone module's additional\_name\_servers output. | `map(list(string))` | `{}` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | The domain name for which the NS record will be created | `string` | n/a | yes |
| <a name="input_workload_public_zone_ns_records"></a> [workload\_public\_zone\_ns\_records](#input\_workload\_public\_zone\_ns\_records) | List of external name servers for the workload public zone | `list(string)` | <pre>[<br/>  "ns-1234.awsdns-33.org.",<br/>  "ns-1234.awsdns-15.net.",<br/>  "ns-1234.awsdns-25.co.uk.",<br/>  "ns-1234.awsdns-45.com."<br/>]</pre> | no |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | The Route 53 hosted zone ID where the NS record should be created | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->