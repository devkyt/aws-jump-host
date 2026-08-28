# ---------------------------------------------
# Jump Host Instance Role With SSM Access
# ---------------------------------------------
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}


# Assumed by the jump host EC2 instance; grants SSM Session Manager access plus any caller-supplied policies
resource "aws_iam_role" "main" {
  name        = var.use_name_prefix ? null : local.name
  name_prefix = var.use_name_prefix ? "${local.name}-" : null

  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = merge(local.tags,
    {
      Name = local.name
      Type = "IAM Role"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.main.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


resource "aws_iam_role_policy_attachment" "additional" {
  for_each = toset(var.additional_iam_policy_arns)

  role       = aws_iam_role.main.name
  policy_arn = each.value
}


# ---------------------------------------------
# Caller-Supplied Inline Policy And Attachment
# ---------------------------------------------
data "aws_iam_policy_document" "additional" {
  dynamic "statement" {
    for_each = var.additional_iam_policy
    content {
      sid       = statement.value.sid
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }

  lifecycle {
    enabled = length(var.additional_iam_policy) > 0
  }
}


resource "aws_iam_policy" "additional" {
  name        = var.use_name_prefix ? null : "${local.name}-additional"
  name_prefix = var.use_name_prefix ? "${local.name}-additional-" : null
  policy      = data.aws_iam_policy_document.additional.json

  tags = merge(local.tags,
    {
      Name = "${local.name}-additional"
      Type = "IAM Policy"
    }
  )

  lifecycle {
    create_before_destroy = true
    enabled               = length(var.additional_iam_policy) > 0
  }
}


resource "aws_iam_role_policy_attachment" "additional_custom" {
  role       = aws_iam_role.main.name
  policy_arn = aws_iam_policy.additional.arn

  lifecycle {
    enabled = length(var.additional_iam_policy) > 0
  }
}


# ---------------------------------------------
# Instance Profile For The Jump Host
# ---------------------------------------------
resource "aws_iam_instance_profile" "main" {
  name        = var.use_name_prefix ? null : local.name
  name_prefix = var.use_name_prefix ? "${local.name}-" : null

  role = aws_iam_role.main.name

  tags = merge(local.tags,
    {
      Name = local.name
      Type = "IAM Instance Profile"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}
