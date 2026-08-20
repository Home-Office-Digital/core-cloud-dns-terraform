# Core Cloud DNS Terraform — Project-Specific Conventions

Project-specific context and conventions for `core-cloud-dns-terraform`. Complements the shared CoreCloud conventions in `common/`.

## Purpose

This repository contains reusable Terraform modules for CoreCloud DNS infrastructure, including:
- Route 53 Profiles with RAM sharing across the AWS Organisation
- Outbound resolver endpoints (POISE, NCSC PDNS, EBSA, APA HOB IBM)
- Inbound resolver endpoints for on-premise to AWS DNS resolution
- DNS Firewall rule groups (blocked domains)
- Internal DNS zones and certificate management
- Public hosted zones and zone delegation

## Module Layout

```
modules/
├── r53-profile/          # Main hybrid DNS module (resolvers, profiles, firewall)
├── internal-dns/         # Private hosted zones for internal services
├── internal-dns-cert/    # ACM certificates for internal DNS names
├── r53-public-zone/      # Public Route 53 hosted zones
└── zone-delegation/      # Cross-account zone delegation
```

## r53-profile Module Conventions

This is the primary module, consumed by the `core-cloud-dns-terragrunt` repo.

### File Organisation

- `r53-outbound-resolver-endpoints.tf` — endpoint resources (POISE, NCSC)
- `r53-outbound-resolver-rules.tf` — forwarding rules and profile associations
- `r53-inbound-resolver-endpoints.tf` — inbound endpoint resources
- `r53-inbound-resolver-rules.tf` — inbound rules
- `r53-profile.tf` — Route 53 Profile resource
- `r53-profile-network.tf` — VPC, subnets, route tables for resolver infrastructure
- `r53-profile-ram-share.tf` — RAM share for org-wide profile distribution
- `r53-firewall.tf` — DNS Firewall rule group and domain lists
- `security-groups.tf` — security groups for resolver endpoints
- `variables.tf` — all input variables
- `outputs.tf` — outputs

### Adding a New Forwarding Rule

When adding a new DNS forwarding rule:

1. Add domain name list variable (e.g. `ncsc_domain_names`) and DNS IP variable to `variables.tf`
2. Add resolver rule resource with `for_each = toset(var.<domain_list>)` pattern in `r53-outbound-resolver-rules.tf`
3. Add profile association resource to bind the rule to the R53 Profile
4. Use `substr(..., 0, 64)` on rule names to respect the 64-character limit
5. Use the appropriate outbound endpoint (`cc_poise_outbound_endpoint` or `cc_ncsc_outbound_endpoint`)

### Resolver Endpoint Mapping

| Endpoint | Use Case | Target IPs Variable |
|----------|----------|---------------------|
| `cc_poise_outbound_endpoint` | On-premise domains (POISE, EBSA, APA HOB IBM) | `poise_dns_ips`, `ebsa_*_dns_ips`, `apa_hob_ibm_*_dns_ips` |
| `cc_ncsc_outbound_endpoint` | Internet DNS via NCSC PDNS (catch-all + explicit) | `ncsc_dns_ips` |

### Rule Precedence

Route 53 Resolver uses most-specific-match-wins. The NCSC catch-all rule (`domain_name = "."`) handles all DNS not matched by a more specific rule. Domain-specific rules (POISE, EBSA, NCSC explicit) always take priority.

## Configuration Source

All variable values come from `config-hybridDNS.yaml` in the `core-cloud-dns-terragrunt` repo, decoded via `yamldecode()` in the terragrunt locals block. When adding new variables:

1. Add the value to `config-hybridDNS.yaml` under the `r53profile` key
2. Pass it through in `hybridDNS/network/terragrunt.hcl` inputs block
3. Declare the variable in this module's `variables.tf`

## Versioning

- Module is versioned via git tags (e.g. `2.3.1`)
- Terragrunt references a pinned `?ref=` tag — bump this after releasing a new version
- Follow semver: breaking variable changes = major, new features = minor, fixes = patch

## Network Context

- Resolver infrastructure lives in the Network account (`975050293884`)
- VPC: `cc-endpoints` (`vpc-0469d2fc432e16753`) in `eu-west-2`
- Subnet ranges for resolvers: `10.252.84.0/24` block, carved into /28s per endpoint type
- Transit gateways provide routing to Prod, NotProd, and Central networks

## Tags

All resources must carry the 8 mandatory tags (defined in `config-hybridDNS.yaml` under `tags` key). Pass `var.tags` to every resource that supports tagging.
