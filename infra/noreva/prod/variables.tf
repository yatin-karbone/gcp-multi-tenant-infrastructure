# ============================================
# PROJECT CONFIGURATION
# ============================================

variable "project_id" {
  description = "GCP Project ID for Noreva production"
  type        = string
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone for VM deployment"
  type        = string
  default     = "us-central1-a"
}

variable "domain" {
  description = "Google Workspace domain"
  type        = string
}

# ============================================
# IAM CONFIGURATION
# ============================================

variable "infra_admins_group_email" {
  description = "Full email address of infrastructure admins group"
  type        = string
}

variable "external_developers_group_email" {
  description = "Full email address of developers group"
  type        = string
}

# ============================================
# NETWORKING
# ============================================

variable "vpc_cidr_range" {
  description = "CIDR range for the VPC subnet"
  type        = string
  default     = "10.1.0.0/24"
}

variable "allow_ssh_from_anywhere" {
  description = "Allow SSH from any IP. For production, set to false and specify allowed_ssh_ranges."
  type        = bool
  default     = false
}

variable "allowed_ssh_ranges" {
  description = "IP CIDR ranges allowed to SSH (only used if allow_ssh_from_anywhere is false)"
  type        = list(string)
  default     = []

  validation {
    condition     = var.allow_ssh_from_anywhere || length(var.allowed_ssh_ranges) > 0
    error_message = "allowed_ssh_ranges must not be empty when allow_ssh_from_anywhere is false."
  }

}

# ============================================
# COMPUTE - VM CONFIGURATION
# ============================================

variable "vm_machine_type" {
  description = "GCP machine type for the application VM"
  type        = string
  default     = "e2-standard-2"
}

variable "vm_boot_disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 100
}

variable "vm_boot_disk_type" {
  description = "Boot disk type (pd-standard, pd-balanced, or pd-ssd)"
  type        = string
  default     = "pd-balanced"
}

# ============================================
# APPLICATION CONFIGURATION
# ============================================

variable "application_domain" {
  description = "Application domain name (e.g., app.company-a.com). Leave empty if not yet configured."
  type        = string
  default     = ""
}

# ============================================
# OPTIONAL FEATURES
# ============================================

variable "create_backup_bucket" {
  description = "Create GCS buckets for uploads and database backups"
  type        = bool
  default     = true
}

variable "create_uptime_check" {
  description = "Create Cloud Monitoring uptime check for the application"
  type        = bool
  default     = false
}

variable "notification_emails" {                                                                                                                                                 
  description = "Email addresses or groups to receive monitoring alerts"                                                                                                         
  type        = list(string)                                                                                                                                                     
  default     = ["alerts@noreva.ai"]
}

variable "log_retention_days" {
  description = "Days to retain logs in GCS archive"
  type        = number
  default     = 90
}