# r53-profile

Creates the central Route 53 Resolver Profile, inbound and outbound resolver
endpoints (POISE and NCSC), resolver rules for internal/forwarded domains, a DNS
Firewall rule group, supporting subnets/NAT gateways, and shares the profile
across the AWS Organization via RAM.

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
| [aws_eip.ncsc_natgw_eip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_internet_gateway.igw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.ncsc_natgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_ram_principal_association.cc_org_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_principal_association) | resource |
| [aws_ram_resource_association.r53_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_resource_association) | resource |
| [aws_ram_resource_share.cc_r53_profile_share](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_resource_share) | resource |
| [aws_route53_resolver_endpoint.cc_inbound_endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_endpoint) | resource |
| [aws_route53_resolver_endpoint.cc_ncsc_outbound_endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_endpoint) | resource |
| [aws_route53_resolver_endpoint.cc_poise_outbound_endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_endpoint) | resource |
| [aws_route53_resolver_firewall_domain_list.custom_blocked_domains](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_firewall_domain_list) | resource |
| [aws_route53_resolver_firewall_rule.aws_managed_rules](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_firewall_rule) | resource |
| [aws_route53_resolver_firewall_rule.custom_block_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_firewall_rule) | resource |
| [aws_route53_resolver_firewall_rule_group.rule_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_firewall_rule_group) | resource |
| [aws_route53_resolver_firewall_rule_group_association.assoc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_firewall_rule_group_association) | resource |
| [aws_route53_resolver_rule.apa_hob_ibm_preprod](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_rule) | resource |
| [aws_route53_resolver_rule.apa_hob_ibm_prod](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_rule) | resource |
| [aws_route53_resolver_rule.cc_ncsc_resolver_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_rule) | resource |
| [aws_route53_resolver_rule.ebsa_notprod](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_rule) | resource |
| [aws_route53_resolver_rule.ebsa_prod](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_rule) | resource |
| [aws_route53_resolver_rule.ncsc_domain_specific](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_rule) | resource |
| [aws_route53_resolver_rule.poise](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_rule) | resource |
| [aws_route53profiles_association.network_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53profiles_association) | resource |
| [aws_route53profiles_profile.cc_r53_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53profiles_profile) | resource |
| [aws_route53profiles_resource_association.apa_hob_ibm_preprod_assoc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53profiles_resource_association) | resource |
| [aws_route53profiles_resource_association.apa_hob_ibm_prod_assoc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53profiles_resource_association) | resource |
| [aws_route53profiles_resource_association.cc_ncsc_resolver_rule_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53profiles_resource_association) | resource |
| [aws_route53profiles_resource_association.ebsa_notprod_assoc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53profiles_resource_association) | resource |
| [aws_route53profiles_resource_association.ebsa_prod_assoc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53profiles_resource_association) | resource |
| [aws_route53profiles_resource_association.ncsc_domain_specific_assoc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53profiles_resource_association) | resource |
| [aws_route53profiles_resource_association.poise_assoc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53profiles_resource_association) | resource |
| [aws_route_table.cc_inbound_resolver_rt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.cc_ncsc_outbound_endpoint_rt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.cc_poise_outbound_endpoint_rt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.ncsc_nat_subnet_rt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.cc_inbound_resolver_assoc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.cc_ncsc_outbound_endpoint_assoc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.cc_poise_outbound_endpoint_assoc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.ncsc_nat_rt_assoc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_security_group.cc_inbound_resolver_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.cc_ncsc_resolver_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.cc_poise_resolver_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_subnet.cc_inbound_endpoint_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.cc_ncsc_natgw_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.cc_ncsc_outbound_endpoint_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.cc_poise_outbound_endpoint_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_apa_hob_ibm_preprod_dns_ips"></a> [apa\_hob\_ibm\_preprod\_dns\_ips](#input\_apa\_hob\_ibm\_preprod\_dns\_ips) | n/a | `list(string)` | n/a | yes |
| <a name="input_apa_hob_ibm_preprod_domain_names"></a> [apa\_hob\_ibm\_preprod\_domain\_names](#input\_apa\_hob\_ibm\_preprod\_domain\_names) | n/a | `list(string)` | n/a | yes |
| <a name="input_apa_hob_ibm_prod_dns_ips"></a> [apa\_hob\_ibm\_prod\_dns\_ips](#input\_apa\_hob\_ibm\_prod\_dns\_ips) | n/a | `list(string)` | n/a | yes |
| <a name="input_apa_hob_ibm_prod_domain_names"></a> [apa\_hob\_ibm\_prod\_domain\_names](#input\_apa\_hob\_ibm\_prod\_domain\_names) | n/a | `list(string)` | n/a | yes |
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | List of availability zones | `list(string)` | n/a | yes |
| <a name="input_aws_association_priority"></a> [aws\_association\_priority](#input\_aws\_association\_priority) | Priority for rule group association | `number` | `200` | no |
| <a name="input_cc_aws_orgnisation_arn"></a> [cc\_aws\_orgnisation\_arn](#input\_cc\_aws\_orgnisation\_arn) | Core Cloud AWS Org ARN | `string` | n/a | yes |
| <a name="input_central_cidrs"></a> [central\_cidrs](#input\_central\_cidrs) | List of CIDRs reachable via the CENTRAL Transit Gateway | `list(string)` | `[]` | no |
| <a name="input_central_transit_gateway_id"></a> [central\_transit\_gateway\_id](#input\_central\_transit\_gateway\_id) | Transit Gateway ID for CENTRAL | `string` | n/a | yes |
| <a name="input_custom_association_priority"></a> [custom\_association\_priority](#input\_custom\_association\_priority) | Priority for rule group association | `number` | `300` | no |
| <a name="input_domain_file_path"></a> [domain\_file\_path](#input\_domain\_file\_path) | Path to the domain list text file | `string` | n/a | yes |
| <a name="input_domain_list_name"></a> [domain\_list\_name](#input\_domain\_list\_name) | Name for the domain list | `string` | n/a | yes |
| <a name="input_ebsa_notprod_dns_ips"></a> [ebsa\_notprod\_dns\_ips](#input\_ebsa\_notprod\_dns\_ips) | n/a | `list(string)` | n/a | yes |
| <a name="input_ebsa_notprod_domain_names"></a> [ebsa\_notprod\_domain\_names](#input\_ebsa\_notprod\_domain\_names) | n/a | `list(string)` | n/a | yes |
| <a name="input_ebsa_prod_dns_ips"></a> [ebsa\_prod\_dns\_ips](#input\_ebsa\_prod\_dns\_ips) | n/a | `list(string)` | n/a | yes |
| <a name="input_ebsa_prod_domain_names"></a> [ebsa\_prod\_domain\_names](#input\_ebsa\_prod\_domain\_names) | n/a | `list(string)` | n/a | yes |
| <a name="input_inbound_resolver_subnet_cidrs"></a> [inbound\_resolver\_subnet\_cidrs](#input\_inbound\_resolver\_subnet\_cidrs) | List of CIDRs for inbound resolver subnets | `list(string)` | n/a | yes |
| <a name="input_natg_subnet_cidrs"></a> [natg\_subnet\_cidrs](#input\_natg\_subnet\_cidrs) | List of CIDRs for NCSC outbound resolver subnets | `list(string)` | n/a | yes |
| <a name="input_ncsc_dns_ips"></a> [ncsc\_dns\_ips](#input\_ncsc\_dns\_ips) | List of NCSC PDNS IP addresses | `list(string)` | n/a | yes |
| <a name="input_ncsc_domain_names"></a> [ncsc\_domain\_names](#input\_ncsc\_domain\_names) | List of domain names to forward explicitly via NCSC PDNS outbound endpoint | `list(string)` | `[]` | no |
| <a name="input_ncsc_resolver_subnet_cidrs"></a> [ncsc\_resolver\_subnet\_cidrs](#input\_ncsc\_resolver\_subnet\_cidrs) | List of CIDRs for NCSC outbound resolver subnets | `list(string)` | n/a | yes |
| <a name="input_notprod_cidrs"></a> [notprod\_cidrs](#input\_notprod\_cidrs) | List of CIDRs reachable via the NOTPROD Transit Gateway | `list(string)` | `[]` | no |
| <a name="input_notprod_transit_gateway_id"></a> [notprod\_transit\_gateway\_id](#input\_notprod\_transit\_gateway\_id) | Transit Gateway ID for NOTPROD | `string` | n/a | yes |
| <a name="input_poise_dns_ips"></a> [poise\_dns\_ips](#input\_poise\_dns\_ips) | n/a | `list(string)` | n/a | yes |
| <a name="input_poise_domain_names"></a> [poise\_domain\_names](#input\_poise\_domain\_names) | n/a | `list(string)` | n/a | yes |
| <a name="input_poise_resolver_subnet_cidrs"></a> [poise\_resolver\_subnet\_cidrs](#input\_poise\_resolver\_subnet\_cidrs) | List of CIDRs for Poise outbound resolver subnets | `list(string)` | n/a | yes |
| <a name="input_prod_cidrs"></a> [prod\_cidrs](#input\_prod\_cidrs) | List of CIDRs reachable via the PROD Transit Gateway | `list(string)` | `[]` | no |
| <a name="input_prod_transit_gateway_id"></a> [prod\_transit\_gateway\_id](#input\_prod\_transit\_gateway\_id) | Transit Gateway ID for PROD (e.g., tgw-xxxxxxxxxxxxxxxxx) | `string` | n/a | yes |
| <a name="input_r53_ram_share_permission_arns"></a> [r53\_ram\_share\_permission\_arns](#input\_r53\_ram\_share\_permission\_arns) | n/a | `list(string)` | n/a | yes |
| <a name="input_rule_group_name"></a> [rule\_group\_name](#input\_rule\_group\_name) | DNS Firewall Rule Group name | `string` | n/a | yes |
| <a name="input_rulegroup_association_priority"></a> [rulegroup\_association\_priority](#input\_rulegroup\_association\_priority) | Priority for rule group association | `number` | `100` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to AWS resources | `map(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID of the network account where the Route 53 profile will be associated | `string` | n/a | yes |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | VPC Name | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_route53_profile_arn"></a> [route53\_profile\_arn](#output\_route53\_profile\_arn) | ARN of the Route 53 Profile |
| <a name="output_route53_profile_id"></a> [route53\_profile\_id](#output\_route53\_profile\_id) | ID of the Route 53 Profile |
| <a name="output_route53_profile_name"></a> [route53\_profile\_name](#output\_route53\_profile\_name) | Name of the Route 53 Profile |
<!-- END_TF_DOCS -->
