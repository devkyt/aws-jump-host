# ---------------------------------------------
# Current AWS Region For The Deployment
# ---------------------------------------------
data "aws_region" "current" {}


# ---------------------------------------------
# Target VPC Where The Jump Host Is Placed
# ---------------------------------------------
data "aws_vpc" "current" {
  id = var.vpc_id
}


# ---------------------------------------------
# Latest Amazon Linux 2023 ARM64 AMI
# ---------------------------------------------
data "aws_ami" "current" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-arm64"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}
