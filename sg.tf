# ---------------------------------------------
# Jump Host Security Group (Zero Inbound)
# ---------------------------------------------
resource "aws_security_group" "main" {
  name        = var.use_name_prefix ? null : local.name
  name_prefix = var.use_name_prefix ? "${local.name}-" : null
  description = "SSM Jump Host security group: zero inbound, scoped outbound"

  vpc_id = var.vpc_id

  tags = merge(local.tags,
    {
      Name = local.name
      Type = "Security Group"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}


# ---------------------------------------------
# Egress To The SSM VPC Endpoints
# ---------------------------------------------
resource "aws_vpc_security_group_egress_rule" "ssm" {
  security_group_id = aws_security_group.main.id

  description                  = "Allow Egress HTTPS to SSM VPC endpoints"
  referenced_security_group_id = aws_security_group.ssm_vpc_endpoints.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443

  tags = merge(local.tags,
    {
      Name = "${local.name}-egress-to-ssm-endpoints-on-port-443"
      Type = "Egress Rule For Security Group"
    }
  )
}


# ---------------------------------------------
# Caller-Defined Egress Rules
# ---------------------------------------------
resource "aws_vpc_security_group_egress_rule" "main" {
  for_each = var.egress

  security_group_id = aws_security_group.main.id

  description                  = coalesce(each.value.description, each.value.protocol == "-1" ? "Allow all egress from Jump Host" : "Allow Egress from Jump Host on port ${each.value.port}")
  cidr_ipv4                    = each.value.cidr_ipv4
  cidr_ipv6                    = each.value.cidr_ipv6
  prefix_list_id               = each.value.prefix_list_id
  referenced_security_group_id = each.value.allowed_security_group_id
  ip_protocol                  = each.value.protocol
  from_port                    = each.value.protocol == "-1" ? null : each.value.port
  to_port                      = each.value.protocol == "-1" ? null : each.value.port

  tags = merge(local.tags,
    {
      Name = "${local.name}-egress-${each.key}"
      Type = "Egress Rule For Security Group"
    }
  )
}


# ---------------------------------------------
# Temporary Internet Egress For Provisioning
# ---------------------------------------------
# Temporary: Allow Egress Traffic To Internet (required for dnf and podman on first start)
resource "aws_vpc_security_group_egress_rule" "nat_internet" {
  security_group_id = aws_security_group.main.id

  description = "Temporary internet access for provisioning"
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_ipv4   = "0.0.0.0/0"

  tags = merge(local.tags,
    {
      Name = "${local.name}-egress-to-internet-on-port-443"
      Type = "Egress Rule For Security Group"
    }
  )

  lifecycle {
    enabled = var.allow_access_to_internet
  }
}


# ---------------------------------------------
# Security Group For The SSM VPC Endpoints
# ---------------------------------------------
resource "aws_security_group" "ssm_vpc_endpoints" {
  name        = var.use_name_prefix ? null : "${local.name}-ssm-vpc-endpoints"
  name_prefix = var.use_name_prefix ? "${local.name}-ssm-vpc-endpoints-" : null
  description = "SSM VPC Endpoints security group: allow inbound https"

  vpc_id = var.vpc_id

  tags = merge(local.tags,
    {
      Name = "${local.name}-ssm-vpc-endpoints"
      Type = "Security Group"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}


# ---------------------------------------------
# HTTPS Ingress From The VPC To Endpoints
# ---------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.ssm_vpc_endpoints.id

  description = "Allow Ingress HTTPS from VPC to SSM VPC Endpoints"
  cidr_ipv4   = data.aws_vpc.current.cidr_block
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443

  tags = merge(local.tags,
    {
      Name = "${local.name}-https-ingress-to-ssm-vpc-endpoints"
      Type = "Ingress Rule For Security Group"
    }
  )
}
