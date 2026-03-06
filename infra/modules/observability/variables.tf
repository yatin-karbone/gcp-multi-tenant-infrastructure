variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "company_name" {
  description = "Company name"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "notification_emails" {
  description = "List of email addresses or groups to receive alerts"
  type        = list(string)
}

variable "disk_alert_threshold" {
  description = "Disk usage percentage to trigger alert"
  type        = number
  default     = 80
}

variable "log_retention_days" {
  description = "Number of days to retain logs in GCS archive"
  type        = number
  default     = 30
}

variable "enable_error_alerts" {
  description = "Enable Django error log alerts"
  type        = bool
  default     = false
}
