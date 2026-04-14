variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "vpc_id" {
  type        = string
  description = "VPC network self_link for private IP peering"
}

variable "instance_name" {
  type        = string
  description = "Cloud SQL instance name"
}

variable "tier" {
  type        = string
  default     = "db-f1-micro"
  description = "Cloud SQL machine tier"
}

variable "db_version" {
  type        = string
  default     = "POSTGRES_15"
  description = "Database version"
}

variable "database_name" {
  type        = string
  description = "Name of the database to create"
}

variable "user_name" {
  type        = string
  description = "Database user name"
}

variable "user_password" {
  type        = string
  sensitive   = true
  description = "Database user password"
}

variable "backup_enabled" {
  type        = bool
  default     = true
  description = "Enable automated backups"
}

variable "backup_retention_days" {
  type        = number
  default     = 7
  description = "Number of days to retain backups"
}

variable "pitr_enabled" {
  type        = bool
  default     = true
  description = "Enable point-in-time recovery"
}

variable "deletion_protection" {
  type        = bool
  default     = false
  description = "Prevent deletion of the Cloud SQL instance"
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = "Labels to apply to resources"
}

variable "availability_type" {
  type        = string
  default     = "ZONAL"
  description = "ZONAL for single zone, REGIONAL for HA"
  validation {
    condition     = contains(["ZONAL", "REGIONAL"], var.availability_type)
    error_message = "Must be ZONAL or REGIONAL."
  }
}

variable "disk_size_gb" {
  type        = number
  default     = 10
  description = "Storage size in GB"
}

variable "disk_autoresize" {
  type        = bool
  default     = true
  description = "Enable automatic storage increase"
}
