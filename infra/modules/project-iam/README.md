# Project IAM Module

Manages IAM permissions for groups at the project level using a flexible, data-driven approach.

This module allows you to define a map of group emails to the list of roles they should receive. It automatically flattens the structure and creates the necessary `google_project_iam_member` resources.

## Usage

module "project_iam" {
  source = "../../modules/project-iam"
  
  project_id = "my-project-123456"

  group_iam_bindings = {
    # Infrastructure Admins
    "infra-admins@karbone.com" = [
      "roles/compute.networkAdmin",
      "roles/compute.securityAdmin",
      "roles/iam.serviceAccountUser",
      "roles/iap.tunnelResourceAccessor"
    ]

    # Developers (Read-only + Connect)
    "developers@karbone.com" = [
      "roles/viewer",
      "roles/iap.tunnelResourceAccessor"
    ]

    # Data Science Team (Specific Access)
    "data-science@karbone.com" = [
      "roles/bigquery.dataViewer",
      "roles/storage.objectViewer"
    ]
  }
}
