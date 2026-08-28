# AWS SSM Jump Host

OpenTofu module for an EC2 jump host accessible via AWS SSM Session Manager. You can find how to use it
in [example](./example/) folder and in the [Examples](#examples) section below.

## Table of Contents

- [Requirements](#requirements)
- [Inputs](#inputs)
- [Outputs](#outputs)
- [Examples](#examples)
  - [Basic Jump Host](#basic-jump-host)
  - [Jump Host with Lattice Access](#jump-host-with-lattice-access)
  - [Internet Access](#internet-access)
- [How To Use](#how-to-use)
  - [Port Forwarding to Services](#port-forwarding-to-services)
  - [VPC Lattice](#vpc-lattice)
- [Troubleshooting](#troubleshooting)

## Requirements

| Name | Version |
|------|---------|
| OpenTofu | >= 1.11 |
| AWS provider | ~> 6.0  |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | Custom name for the jump host resources. Defaults to {app}-{env}-jump-host | `string` | `null` | no |
| `app` | Application name | `string` | - | yes |
| `env` | Target environment | `string` | - | yes |
| `vpc_id` | VPC ID where Jump Host will be located | `string` | - | yes |
| `subnet_id` | Subnet ID where Jump Host will be located | `string` | - | yes |
| `allow_access_to_internet` | Allow access to internet from the Jump Host | `bool` | `false` | no |
| `instance_type` | EC2 instance type for the Jump Host | `string` | `"t4g.small"` | no |
| `storage_size_gb` | Root EBS volume size in GB | `number` | `32` | no |
| `egress` | Egress rules for the Jump Host security group | `map(object)` | `{}` | no |
| `additional_iam_policy_arns` | Additional IAM policy ARNs for the Jump Host role | `list(string)` | `[]` | no |
| `additional_iam_policy` | Additional IAM policy statements for the Jump Host role | `list(object)` | `[]` | no |
| `use_name_prefix` | Use name_prefix instead of a fixed name for created resources, so AWS appends a unique suffix | `bool` | `false` | no |
| `include_default_tags` | Whether or not to attach default tags specified in module | `bool` | `true` | no |
| `tags` | Tags to apply to EC2 and the related resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `instance_id` | ID of the created EC2 instance |
| `instance_arn` | ARN of the created EC2 instance |
| `security_group_id` | ID of the created security group |
| `iam_role_arn` | ARN of the created IAM role |
| `iam_role_name` | Name of the created IAM role |
| `iam_instance_profile_arn` | ARN of the created IAM instance profile |

## Examples

### Basic Jump Host

A minimal jump host with egress to an RDS database and ElastiCache Redis.

```hcl
module "jump_host" {
  source = "git@github.com:devkyt/aws-jump-host.git?ref=main&depth=1"

  app = "platform"
  env = "experiment"

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
  }
}
```

### Jump Host with Lattice Access

Adding egress to VPC Lattice services via prefix list and an IAM policy for invoking them.

```hcl
data "aws_ec2_managed_prefix_list" "vpc_lattice" {
  name = "com.amazonaws.eu-central-1.vpc-lattice"
}

module "jump_host" {
  source = "git@github.com:devkyt/aws-jump-host.git?ref=main&depth=1"

  app = "platform"
  env = "experiment"

  vpc_id    = "vpc-0123456789abcdef0"
  subnet_id = "subnet-0123456789abcdef0"

  egress = {
    "rds-postgres" = {
      port                      = 5432
      allowed_security_group_id = "sg-0123456789abcdef0"
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
}
```

### Internet Access

Allowing outbound internet access from the jump host.

```hcl
module "jump_host" {
  source = "git@github.com:devkyt/aws-jump-host.git?ref=main&depth=1"

  app = "platform"
  env = "experiment"

  vpc_id    = "vpc-0123456789abcdef0"
  subnet_id = "subnet-0123456789abcdef0"

  allow_access_to_internet = true
}
```

## How To Use

### Port Forwarding to Services

Start port forwarding to an RDS/ElastiCache or other AWS target:

```bash
# e.g. RDS Postgres on port 5432
aws ssm start-session --target i-0ba55676bb4f7b0e8 --document-name AWS-StartPortForwardingSessionToRemoteHost --parameters '{"host":["your-db.cluster-xxxx.eu-central-1.rds.amazonaws.com"],"portNumber":["5432"],"localPortNumber":["5432"]}'

# e.g. ElastiCache Redis on port 6379
aws ssm start-session --target i-0ba55676bb4f7b0e8 --document-name AWS-StartPortForwardingSessionToRemoteHost --parameters '{"host":["your-redis.xxxx.euc1.cache.amazonaws.com"],"portNumber":["6379"],"localPortNumber":["6379"]}'
```

Connect to the forwarded service locally:

```bash
# Postgres
psql -h localhost -p 5432 -U myuser -d mydb

# Redis
redis-cli -h localhost -p 6379
```

### VPC Lattice

Start port forwarding via HTTP:

```bash
aws ssm start-session --target i-0ba55676bb4f7b0e8 --document-name AWS-StartPortForwardingSession --parameters '{"portNumber":["8080"],"localPortNumber":["8080"]}'
```

Or start port forwarding via HTTPS if server is using TLS:

```bash
aws ssm start-session --target i-0ba55676bb4f7b0e8 --document-name AWS-StartPortForwardingSession --parameters '{"portNumber":["8443"],"localPortNumber":["8443"]}'
```

Connect to required instance by DNS and port:

```bash
# http
curl -vH "Host: custom.domain.name:3000" http://localhost:8080/health

# https
curl -vH "Host: custom.domain.name" https://localhost:8443/health
```

## Troubleshooting

Connect to instance:

```bash
aws ssm start-session --target i-0bcb8ba1ba02256b3
```

Check the service status:

```bash
sudo systemctl status sigv4-proxy-http sigv4-proxy-https
```

Check if service is even defined:

```bash
ls -la /usr/local/bin/aws-sigv4-proxy
```

Check logs:

```bash
sudo cat /var/log/cloud-init-output.log | tail -80
```

## License

Licensed under the Apache License, Version 2.0.

Copyright 2026 Kyrylo Tykhanskyi.
