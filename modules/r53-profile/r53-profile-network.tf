# ---------------------------------------------
# Local Maps for Resolver Subnet Configuration
# ---------------------------------------------
locals {
  poise_map = zipmap(
    range(length(var.poise_resolver_subnet_cidrs)),
    [for i in range(length(var.poise_resolver_subnet_cidrs)) : {
      cidr = var.poise_resolver_subnet_cidrs[i]
      az   = var.availability_zones[i]
    }]
  )

  ncsc_map = zipmap(
    range(length(var.ncsc_resolver_subnet_cidrs)),
    [for i in range(length(var.ncsc_resolver_subnet_cidrs)) : {
      cidr = var.ncsc_resolver_subnet_cidrs[i]
      az   = var.availability_zones[i]
    }]
  )

  natg_map = zipmap(
    range(length(var.natg_subnet_cidrs)),
    [for i in range(length(var.natg_subnet_cidrs)) : {
      cidr = var.natg_subnet_cidrs[i]
      az   = var.availability_zones[i]
    }]
  )

  inbound_map = zipmap(
    range(length(var.inbound_resolver_subnet_cidrs)),
    [for i in range(length(var.inbound_resolver_subnet_cidrs)) : {
      cidr = var.inbound_resolver_subnet_cidrs[i]
      az   = var.availability_zones[i]
    }]
  )
}

# ------------------------------
# Internet Gateway for the VPC
# ------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

# -----------------------------------
# Resolver Subnets (INBOUND ONLY)
# -----------------------------------
resource "aws_subnet" "cc_inbound_endpoint_subnet" {
  for_each = local.inbound_map

  vpc_id            = var.vpc_id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name     = "cc-inbound-resolver-${each.value.az}"
    Resolver = "inbound"
  }
}

# -----------------------------------
# Resolver Subnets (POISE OUTBOUND)
# -----------------------------------
resource "aws_subnet" "cc_poise_outbound_endpoint_subnet" {
  for_each = local.poise_map

  vpc_id            = var.vpc_id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name     = "cc-poise-outbound-resolver-endpoint-${each.value.az}"
    Resolver = "poise"
  }
}

# -----------------------------------
# Resolver Subnets (NCSC OUTBOUND)
# -----------------------------------
resource "aws_subnet" "cc_ncsc_outbound_endpoint_subnet" {
  for_each = local.ncsc_map

  vpc_id            = var.vpc_id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name     = "cc-ncsc-outbound-resolver-endpoint-${each.value.az}"
    Resolver = "ncsc"
  }
}

# ------------------------------------------------------
# Public NAT Gateway and Elastic IPs (NAT GW in public subnet)
# ------------------------------------------------------
resource "aws_subnet" "cc_ncsc_natgw_subnet" {
  for_each = local.natg_map

  #checkov:skip=CKV_AWS_130:Public IP required for ncsc NATGW
  vpc_id                  = var.vpc_id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = {
    Name = "cc-ncsc-natgw-subnet-${each.key}"
  }
}

resource "aws_eip" "ncsc_natgw_eip" {
  for_each = aws_subnet.cc_ncsc_natgw_subnet
  domain   = "vpc"

  tags = {
    Name = "ncsc-natgw-eip-${each.key}"
  }
}

resource "aws_nat_gateway" "ncsc_natgw" {
  for_each      = aws_subnet.cc_ncsc_natgw_subnet
  subnet_id     = each.value.id
  allocation_id = aws_eip.ncsc_natgw_eip[each.key].id

  tags = {
    Name = "ncsc-natgw-${each.key}"
  }
}

# ------------------------------------------------------
# Public Route Table for NAT Subnet to IGW (NCSC only)
# ------------------------------------------------------
resource "aws_route_table" "ncsc_nat_subnet_rt" {
  for_each = aws_subnet.cc_ncsc_natgw_subnet

  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "ncsc-nat-subnet-rt-${each.key}"
  }
}

resource "aws_route_table_association" "ncsc_nat_rt_assoc" {
  for_each = aws_subnet.cc_ncsc_natgw_subnet

  subnet_id      = each.value.id
  route_table_id = aws_route_table.ncsc_nat_subnet_rt[each.key].id
}

# ----------------------------------------------------------
# Route Tables for Resolver Endpoints (POISE/NCSC/INBOUND)
# ----------------------------------------------------------
resource "aws_route_table" "cc_poise_outbound_endpoint_rt" {
  for_each = aws_subnet.cc_poise_outbound_endpoint_subnet
  vpc_id   = var.vpc_id

  # Prod CIDRs via Prod TGW
  dynamic "route" {
    for_each = toset(var.prod_cidrs)
    content {
      cidr_block         = route.value
      transit_gateway_id = var.prod_transit_gateway_id
    }
  }

  # NotProd CIDRs via NotProd TGW
  dynamic "route" {
    for_each = toset(var.notprod_cidrs)
    content {
      cidr_block         = route.value
      transit_gateway_id = var.notprod_transit_gateway_id
    }
  }

  # Central CIDRs via Central TGW
  dynamic "route" {
    for_each = toset(var.central_cidrs)
    content {
      cidr_block         = route.value
      transit_gateway_id = var.central_transit_gateway_id
    }
  }

  tags = { Name = "cc-poise-outbound-resolver-endpoints-rt-${each.key}" }
}


resource "aws_route_table" "cc_ncsc_outbound_endpoint_rt" {
  for_each = aws_subnet.cc_ncsc_outbound_endpoint_subnet

  vpc_id = var.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ncsc_natgw[each.key].id
  }

  tags = {
    Name = "cc-ncsc-outbound-resolver-endpoints-rt-${each.key}"
  }
}

resource "aws_route_table" "cc_inbound_resolver_rt" {
  for_each = aws_subnet.cc_inbound_endpoint_subnet
  vpc_id   = var.vpc_id

  # Prod CIDRs via Prod TGW
  dynamic "route" {
    for_each = toset(var.prod_cidrs)
    content {
      cidr_block         = route.value
      transit_gateway_id = var.prod_transit_gateway_id
    }
  }

  # NotProd CIDRs via NotProd TGW
  dynamic "route" {
    for_each = toset(var.notprod_cidrs)
    content {
      cidr_block         = route.value
      transit_gateway_id = var.notprod_transit_gateway_id
    }
  }

  # Central CIDRs via Central TGW
  dynamic "route" {
    for_each = toset(var.central_cidrs)
    content {
      cidr_block         = route.value
      transit_gateway_id = var.central_transit_gateway_id
    }
  }

  tags = {
    Name = "cc-inbound-resolver-endpoints-rt-${each.key}"
  }
}

# -----------------------------------------------------
# Route Table Associations for POISE/NCSC/INBOUND
# -----------------------------------------------------
resource "aws_route_table_association" "cc_poise_outbound_endpoint_assoc" {
  for_each = aws_subnet.cc_poise_outbound_endpoint_subnet

  subnet_id      = each.value.id
  route_table_id = aws_route_table.cc_poise_outbound_endpoint_rt[each.key].id
}

resource "aws_route_table_association" "cc_ncsc_outbound_endpoint_assoc" {
  for_each = aws_subnet.cc_ncsc_outbound_endpoint_subnet

  subnet_id      = each.value.id
  route_table_id = aws_route_table.cc_ncsc_outbound_endpoint_rt[each.key].id
}

resource "aws_route_table_association" "cc_inbound_resolver_assoc" {
  for_each = aws_subnet.cc_inbound_endpoint_subnet

  subnet_id      = each.value.id
  route_table_id = aws_route_table.cc_inbound_resolver_rt[each.key].id
}
