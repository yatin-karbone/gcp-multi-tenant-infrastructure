output "bindings_created" {
  description = "List of all IAM bindings created"
  value       = [for k, v in google_project_iam_member.group_roles : "${v.role} -> ${v.member}"]
}