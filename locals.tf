locals {
  name = coalesce(var.name, "${var.env}-ssm-jump-host")

  ssm_endpoints = [
    "com.amazonaws.${data.aws_region.current.region}.ssm",
    "com.amazonaws.${data.aws_region.current.region}.ssmmessages",
    "com.amazonaws.${data.aws_region.current.region}.ec2messages",
  ]

  default_tags = var.include_default_tags ? {
    Environment = var.env
    Env         = var.env
    Terraform   = "true"
    ManagedBy   = "Terraform"
  } : {}

  tags = merge(local.default_tags, var.tags)
}
