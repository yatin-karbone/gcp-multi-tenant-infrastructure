locals {
  # Flatten the map into a list of objects for for_each
  # Input: { "admin@Example.com" = ["role1", "role2"] }
  # Output: [ { email = "admin@...", role = "role1" }, { email = "admin@...", role = "role2" } ]
  iam_bindings = flatten([
    for email, roles in var.group_iam_bindings : [
      for role in roles : {
        email = email
        role  = role
        # Create a unique key for for_each
        key   = "${email}-${role}"
      }
    ]
  ])
}

resource "google_project_iam_member" "group_roles" {
  for_each = {
    for binding in local.iam_bindings : binding.key => binding
  }

  project = var.project_id
  role    = each.value.role
  member  = "group:${each.value.email}"
}