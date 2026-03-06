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
  default     = "us-east4-a"
}

variable "vpc_cidr_range" {
  description = "CIDR range for the VPC subnet"
  type        = string
  default     = "10.0.10.0/24" # Different range than prod (usually 10.0.0.0/24)
}

variable "infra_admins_group_email" {
  description = "Email of the infrastructure admins group"
  type        = string
}

variable "external_developers_group_email" {
  description = "Email of the external developers group"
  type        = string
}

variable "allow_ssh_from_anywhere" {
  description = "Allow SSH from 0.0.0.0/0"
  type        = bool
  default     = false
}

variable "allowed_ssh_ranges" {
  description = "List of CIDR ranges allowed to SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"] # For dev, maybe more permissive, or restrict to VPN
}

variable "vm_machine_type" {
  description = "Machine type for the app VM"
  type        = string
  default     = "e2-small" # Smaller instance for Dev
}

variable "vm_boot_disk_size_gb" {
  description = "Boot disk size for the app VM"
  type        = number
  default     = 20
}

variable "vm_boot_disk_type" {
  description = "Boot disk type"
  type        = string
  default     = "pd-standard"
}

variable "create_backup_bucket" {
  description = "Whether to create backup buckets"
  type        = bool
  default     = true
}

variable "create_uptime_check" {
  description = "Whether to create uptime checks"
  type        = bool
  default     = false # Usually false for dev
}

variable "notification_emails" {
  description = "Email addresses or groups to receive monitoring alerts"
  type        = list(string)
  default     = ["alerts@noreva.ai"]
}

variable "log_retention_days" {
  description = "Days to retain logs in GCS archive"
  type        = number
  default     = 30
}