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
  default     = "us-east4-a"
  description = "GCP zone"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Environment name"
}

# Networking
variable "app_subnet_cidr" {
  type        = string
  description = "CIDR range for the Karbone app subnet"
}

variable "existing_vpc_name" {
  type        = string
  description = "Name of the existing VPC in this project"
}

variable "existing_router_name" {
  type        = string
  description = "Name of the existing Cloud Router"
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
  default     = "db-f1-micro"
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

# Observability
variable "notification_emails" {
  type        = list(string)
  default     = []
  description = "Email addresses for alert notifications"
}

# Labels
variable "labels" {
  type        = map(string)
  default     = {}
  description = "Labels to apply to all resources"
}
