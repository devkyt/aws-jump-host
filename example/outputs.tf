output "instance_id" {
  description = "ID of the created EC2 instance"
  value       = module.jump_host.instance_id
}


output "security_group_id" {
  description = "ID of the created security group"
  value       = module.jump_host.security_group_id
}


output "iam_role_name" {
  description = "Name of the created IAM role"
  value       = module.jump_host.iam_role_name
}
