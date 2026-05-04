variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  default     = "us-east4"
  description = "GCP region"
}

variable "zone" {
  type        = string
  default     = "us-east4-c"
  description = "GCP zone"
}

variable "environment" {
  type        = string
  default     = "prod"
  description = "Environment name"
}

# Networking — prod creates its own VPC
variable "vpc_cidr_range" {
  type        = string
  description = "CIDR range for the prod VPC subnet"
}

variable "office_allowed_ips" {
  type        = list(string)
  default     = []
  description = "List of CIDRs allowed to access HTTPS (port 443). Used for office/dev access restriction."
}

# VM
variable "vm_machine_type" {
  type        = string
  default     = "e2-standard-2"
  description = "VM machine type"
}

variable "vm_boot_disk_size_gb" {
  type        = number
  default     = 100
  description = "Boot disk size in GB"
}

variable "vm_boot_disk_type" {
  type        = string
  default     = "pd-balanced"
  description = "Boot disk type"
}

# Cloud SQL
variable "db_tier" {
  type        = string
  default     = "db-g1-small"
  description = "Cloud SQL machine tier"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "Password for the Cloud SQL database user"
}

# IAM
variable "infra_admins_group_email" {
  type        = string
  description = "Google Group email for infra admins"
}

variable "external_developers_group_email" {
  type        = string
  description = "Google Group email for external developers with IAP SSH access"
}

# Observability
variable "notification_emails" {
  type        = list(string)
  default     = []
  description = "Email addresses for alert notifications"
}

variable "log_retention_days" {
  type    = number
  default = 30
}

# GitHub Actions
variable "github_repo" {
  type        = string
  description = "GitHub repository in 'owner/repo' format — used to scope WIF access (e.g. 'karbone-org/karbone')"
}

# Labels
variable "labels" {
  type        = map(string)
  default     = {}
  description = "Labels to apply to all resources"
}
