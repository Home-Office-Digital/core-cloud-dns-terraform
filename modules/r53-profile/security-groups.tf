##############################
# Outbound Resolver SG (Poise + EBSA)
##############################

resource "aws_security_group" "cc_poise_resolver_sg" {
  name        = "cc-poise-resolver-sg"

  # MUST stay EXACTLY the same or AWS forces replacement
  description = "Security Group for Poise outbound resolver DNS traffic"

  vpc_id = var.vpc_id

  # -----------------
  # Poise DNS
  # -----------------
  dynamic "egress" {
    for_each = var.poise_dns_ips
    content {
      from_port   = 53
      to_port     = 53
      protocol    = "udp"
      cidr_blocks = ["${egress.value}/32"]
      description = "Allow outbound DNS (UDP) to Poise DNS ${egress.value}"
    }
  }

  dynamic "egress" {
    for_each = var.poise_dns_ips
    content {
      from_port   = 53
      to_port     = 53
      protocol    = "tcp"
      cidr_blocks = ["${egress.value}/32"]
      description = "Allow outbound DNS (TCP) to Poise DNS ${egress.value}"
    }
  }

  # -----------------
  # EBSA NOTPROD DNS
  # -----------------
  dynamic "egress" {
    for_each = var.ebsa_notprod_dns_ips
    content {
      from_port   = 53
      to_port     = 53
      protocol    = "udp"
      cidr_blocks = ["${egress.value}/32"]
      description = "Allow outbound DNS (UDP) to EBSA NOTPROD DNS ${egress.value}"
    }
  }

  dynamic "egress" {
    for_each = var.ebsa_notprod_dns_ips
    content {
      from_port   = 53
      to_port     = 53
      protocol    = "tcp"
      cidr_blocks = ["${egress.value}/32"]
      description = "Allow outbound DNS (TCP) to EBSA NOTPROD DNS ${egress.value}"
    }
  }

  # -----------------
  # EBSA PROD DNS
  # -----------------
  dynamic "egress" {
    for_each = var.ebsa_prod_dns_ips
    content {
      from_port   = 53
      to_port     = 53
      protocol    = "udp"
      cidr_blocks = ["${egress.value}/32"]
      description = "Allow outbound DNS (UDP) to EBSA PROD DNS ${egress.value}"
    }
  }

  dynamic "egress" {
    for_each = var.ebsa_prod_dns_ips
    content {
      from_port   = 53
      to_port     = 53
      protocol    = "tcp"
      cidr_blocks = ["${egress.value}/32"]
      description = "Allow outbound DNS (TCP) to EBSA PROD DNS ${egress.value}"
    }
  }
}


##############################
# NCSC Outbound Resolver SG
##############################

resource "aws_security_group" "cc_ncsc_resolver_sg" {
  name        = "cc-ncsc-resolver-sg"
  description = "Security Group for NCSC outbound resolver DNS traffic"
  vpc_id      = var.vpc_id

  # Allow outbound DNS (UDP + TCP) to each NCSC DNS IP
  dynamic "egress" {
    for_each = var.ncsc_dns_ips
    content {
      from_port   = 53
      to_port     = 53
      protocol    = "udp"
      cidr_blocks = ["${egress.value}/32"]
      description = "Allow outbound DNS (UDP) to NCSC PDNS ${egress.value}"
    }
  }

  dynamic "egress" {
    for_each = var.ncsc_dns_ips
    content {
      from_port   = 53
      to_port     = 53
      protocol    = "tcp"
      cidr_blocks = ["${egress.value}/32"]
      description = "Allow outbound DNS (TCP) to NCSC PDNS ${egress.value}"
    }
  }
}


##############################
# Inbound Resolver SG
##############################

resource "aws_security_group" "cc_inbound_resolver_sg" {
  name        = "cc-inbound-resolver-sg"
  description = "SG for inbound DNS resolver"
  vpc_id      = var.vpc_id

  # Allow inbound DNS from on-prem / VPC CIDRs
  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["10.0.0.0/8"] # Adjust to your on-prem/VPC IP range
    description = "Allow inbound DNS queries over UDP"
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    description = "Allow inbound DNS queries over TCP"
  }

  # Outbound typically needed for DNS responses
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["10.0.0.0/8", "192.168.0.0/16"]
    description = "Allow DNS responses over UDP"
  }

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8", "192.168.0.0/16"]
    description = "Allow DNS responses over TCP"
  }

}
