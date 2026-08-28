# ---------------------------------------------
# SSM-Managed Jump Host EC2 Instance
# ---------------------------------------------
resource "aws_instance" "main" {
  ami           = data.aws_ami.current.id
  instance_type = var.instance_type

  subnet_id                   = var.subnet_id
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.main.id]

  iam_instance_profile = aws_iam_instance_profile.main.name

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 only
    http_put_response_hop_limit = 1          # Prevent SSRF token relay
    instance_metadata_tags      = "disabled"
  }

  root_block_device {
    volume_size = var.storage_size_gb
    volume_type = "gp3"
    encrypted   = true
  }

  user_data_base64 = base64encode(templatefile
    (
      "${path.module}/templates/userdata.sh.tftpl", { region = data.aws_region.current.region }
    )
  )
  user_data_replace_on_change = true

  tags = merge(local.tags,
    {
      Name = local.name
      Type = "SSM Jump Host"
    }
  )
}


# ---------------------------------------------
# Interface VPC Endpoints For SSM Access
# ---------------------------------------------
resource "aws_vpc_endpoint" "ssm" {
  for_each = toset(local.ssm_endpoints)

  vpc_id              = var.vpc_id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = [var.subnet_id]
  security_group_ids = [aws_security_group.ssm_vpc_endpoints.id]

  tags = merge(local.tags,
    {
      Name = each.value
      Type = "SSM VPC Endpoint"
    }
  )
}
