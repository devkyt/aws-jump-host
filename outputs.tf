output "instance_id" {
  description = "ID of the created EC2 instance"
  value       = aws_instance.main.id
}


output "instance_arn" {
  description = "ARN of the created EC2 instance"
  value       = aws_instance.main.arn
}


output "security_group_id" {
  description = "ID of the created security group"
  value       = aws_security_group.main.id
}


output "iam_role_arn" {
  description = "ARN of the created IAM role"
  value       = aws_iam_role.main.arn
}


output "iam_role_name" {
  description = "Name of the created IAM role"
  value       = aws_iam_role.main.name
}


output "iam_instance_profile_arn" {
  description = "ARN of the created IAM instance profile"
  value       = aws_iam_instance_profile.main.arn
}
