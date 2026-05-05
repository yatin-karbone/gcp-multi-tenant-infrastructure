variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-east4"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-east4-c"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "test"
}

variable "existing_vpc_name" {
  description = "Name of the existing VPC (from pnl-pipeline)"
  type        = string
}

variable "office_allowed_ips" {
  description = "CIDR ranges allowed to reach port 443"
  type        = list(string)
  default     = []
}

variable "vm_machine_type" {
  description = "GCE machine type"
  type        = string
  default     = "e2-standard-2"
}

variable "vm_boot_disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 100
}

variable "vm_boot_disk_type" {
  description = "Boot disk type"
  type        = string
  default     = "pd-balanced"
}

variable "db_tier" {
  description = "Cloud SQL machine tier"
  type        = string
  default     = "db-f1-micro"
}

variable "db_password" {
  description = "Password for the karbone_app database user"
  type        = string
  sensitive   = true
}

variable "infra_admins_group_email" {
  description = "Google group email for infra admins"
  type        = string
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
