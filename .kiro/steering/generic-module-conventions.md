---
inclusion: always
---

# Generic, reusable Terraform module — conventions & guardrails

This repository is a **public, general-purpose Terraform module** for Route 53 / DNS
infrastructure. It is intended to be usable by anyone, in any AWS account. Treat it
like an open-source module, not an internal project.

## Golden rule

**Nothing organisation-specific may be committed here.** Everything environment- or
organisation-specific must be supplied by the consumer via **input variables** (with
generic, non-identifying defaults). Modules document only **purpose, inputs, and
outputs**.

## Never add (hard bans)

Do not introduce any of the following into `.tf`, `.md`, `.yaml`, examples, comments,
resource names, or defaults:

- **AWS account IDs** (12-digit numbers). Use `data.aws_caller_identity.current` or a variable.
- **Real internal IPs / CIDRs** — on-prem resolver IPs, internal ranges (e.g. `10.228.x`,
  `10.223.x`), or any address that reveals a real network. Use variables; if an example is
  needed, use obviously-fake values (`10.0.0.10`, `192.0.2.0/24` TEST-NET).
- **Real hostnames / domains** — e.g. anything ending in a real corporate domain, or real
  private-zone names. Use `example.com`, `example.internal`, `example.phz` in examples/defaults.
- **Resource IDs** — `vpc-…`, `subnet-…`, `tgw-…`, and org IDs `o-…`. Always variables.
- **Organisation / tenant / project names** — including but not limited to: `core cloud`,
  `corecloud`, `cc-`/`cc_` name prefixes, `poise`, `ebsa`, `apa`, `ncsc`, `andromeda`,
  `homeoffice`, and similar internal codenames. Use neutral names.
- **Organisation-specific tags** — no hardcoded cost-centre / account-code / portfolio /
  owner values. Accept a generic `tags` (`map(string)`) variable and pass it through.
- **Consumer/pipeline coupling** — do not describe or assume a specific consuming repo,
  terragrunt layout, config file, CI role, or account. The module must stand alone.

## Naming

- Use **neutral, function-describing** names: `outbound_resolver_endpoint`,
  `resolver_profile`, `dns_firewall_rule_group` — not `cc_*` or tenant-named
  (`cc_poise_outbound_endpoint`). Prefer variables for anything that varies by deployment
  (e.g. `outbound_endpoints` as a map/list, not hardcoded POISE/NCSC endpoints).

## Documentation

- Each module's README covers only: **what it does, inputs, outputs, and a generic usage
  example.** No references to any specific organisation, account, network, or consumer.

## When asked to add organisation-specific behaviour

If a request would require adding any of the banned items above (e.g. "add the NCSC
forwarder", "use our account id", "tag with our cost-centre"), do **not** hardcode it here.
Instead:
1. Add a **variable** with a generic default (or no default).
2. Implement the behaviour generically in terms of that variable.
3. The organisation-specific **value** belongs in the *consumer* (e.g. a private
   terragrunt repo), never in this module.

## Why this exists

A previous steering file baked Core Cloud specifics (account id, VPC id, internal CIDRs,
tenant forwarder names) into this public repo and propagated them into every change. It
was removed. This file replaces it with the opposite intent: keep the module generic and
prevent re-introduction. A CI check should back this up for non-agent (human) contributions.
