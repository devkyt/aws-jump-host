locals {
  app    = "whatever"
  env    = "experiment"
  region = "eu-central-1"

  tags = {
    Name        = local.app
    Environment = local.env
    Region      = local.region
  }
}

terraform {
  backend "s3" {
    bucket = "terraform-experiments-state"
    region = "eu-central-1"
    key    = "whatever/terraform.tfstate"
  }
}


provider "aws" {
  region = local.region
}


data "aws_ec2_managed_prefix_list" "vpc_lattice" {
  name = "com.amazonaws.${local.region}.vpc-lattice"
}


module "jump_host" {
  source = "git@github.com:devkyt/aws-jump-host.git?ref=main&depth=1"

  app = local.app
  env = local.env

  vpc_id    = "vpc-0123456789abcdef0"
  subnet_id = "subnet-0123456789abcdef0"

  egress = {
    "rds-postgres" = {
      port                      = 5432
      allowed_security_group_id = "sg-0123456789abcdef0"
    }
    "elasticache-redis" = {
      port                      = 6379
      allowed_security_group_id = "sg-0123456789abcdef1"
    }
    "vpc-https" = {
      port      = 443
      cidr_ipv4 = "10.0.0.0/16"
    }
    "lattice-http" = {
      port           = 8080
      prefix_list_id = data.aws_ec2_managed_prefix_list.vpc_lattice.id
    }
  }

  additional_iam_policy = [
    {
      sid       = "AllowInvokeLatticeServices"
      effect    = "Allow"
      actions   = ["vpc-lattice-svcs:Invoke"]
      resources = ["arn:aws:vpc-lattice:eu-central-1:123456789012:service/svc-0123456789abcdef0/*"]
    }
  ]

  tags = local.tags
}
