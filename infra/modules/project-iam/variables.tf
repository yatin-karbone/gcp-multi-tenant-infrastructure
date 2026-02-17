variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "group_iam_bindings" {
  description = "Map of group emails to a list of IAM roles they should be granted."
  type        = map(list(string))
  # Example:
  # {
  #   "admins@karbone.com" = ["roles/owner", "roles/storage.admin"]
  #   "devs@karbone.com"   = ["roles/viewer"]
  # }
}