variable "name" {
  description = "Custom name for the jump host resources. Defaults to {env}-ssm-jump-host"
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.name == null ? true : length(var.name) > 0
    error_message = "Name cannot be empty if provided."
  }

  validation {
    condition     = var.name == null ? true : can(regex("^[a-z0-9-]+$", var.name))
    error_message = "Name must contain only lowercase letters, numbers, and hyphens."
  }
}


variable "env" {
  description = "Target environment"
  type        = string

  validation {
    condition     = length(var.env) > 0
    error_message = "Environment cannot be empty."
  }

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.env))
    error_message = "Environment must contain only lowercase letters, numbers, and hyphens."
  }
}


variable "vpc_id" {
  description = "VPC ID where Jump Host will be located"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-f0-9]{8,}$", var.vpc_id))
    error_message = "VPC ID must be in valid format (e.g., vpc-0abc1234def56789a)."
  }
}


variable "subnet_id" {
  description = "Subnet ID where Jump Host will be located"
  type        = string

  validation {
    condition     = can(regex("^subnet-[a-f0-9]{8,}$", var.subnet_id))
    error_message = "Subnet ID must be in valid format (e.g., subnet-0abc1234def56789a)."
  }
}


variable "allow_access_to_internet" {
  description = "Allow access to internet from the Jump Host"
  type        = bool
  default     = false
}


variable "instance_type" {
  description = "EC2 instance type for the Jump Host"
  type        = string
  default     = "t4g.small"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]*\\.[a-z0-9]+$", var.instance_type))
    error_message = "Instance type must be in valid format (e.g., t4g.micro, t4g.nano)."
  }
}


variable "storage_size_gb" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 32

  validation {
    condition     = var.storage_size_gb >= 8 && var.storage_size_gb <= 16384
    error_message = "Storage size must be between 8 and 16384 GB."
  }
}


variable "egress" {
  description = "Egress rules for the Jump Host security group"
  type = map(object({
    port                      = optional(number)
    protocol                  = optional(string, "tcp")
    description               = optional(string)
    cidr_ipv4                 = optional(string)
    cidr_ipv6                 = optional(string)
    prefix_list_id            = optional(string)
    allowed_security_group_id = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.egress : length(compact([v.cidr_ipv4, v.cidr_ipv6, v.prefix_list_id, v.allowed_security_group_id])) == 1
    ])
    error_message = "Each egress rule must specify exactly one destination: cidr_ipv4, cidr_ipv6, prefix_list_id, or allowed_security_group_id."
  }

  validation {
    condition = alltrue([
      for k, v in var.egress : v.protocol == "-1" || (v.port != null && v.port >= 1 && v.port <= 65535)
    ])
    error_message = "Port is required (1-65535) unless protocol is '-1'."
  }
}


variable "additional_iam_policy_arns" {
  description = "Additional IAM policy ARNs for the Jump Host role"
  type        = list(string)
  default     = []
}


variable "additional_iam_policy" {
  description = "Additional IAM policy statements for the Jump Host role"
  type = list(object({
    sid       = string
    effect    = string
    actions   = list(string)
    resources = list(string)
  }))
  default = []

  validation {
    condition     = alltrue([for s in var.additional_iam_policy : contains(["Allow", "Deny"], s.effect)])
    error_message = "Effect must be 'Allow' or 'Deny'."
  }
}


variable "use_name_prefix" {
  description = "Use name_prefix instead of a fixed name for the resources this module creates, so AWS appends a unique suffix"
  type        = bool
  default     = false
}


variable "include_default_tags" {
  description = "Whether or not to attach default tags specified in module"
  type        = bool
  default     = true
}


variable "tags" {
  description = "Tags to apply to EC2 and the related resources"
  type        = map(string)
  default     = {}
}
