variable "project_id" {
  description = "GCP Project ID where the VPC will be created"
  type        = string

  validation {
    condition     = length(var.project_id) > 0
    error_message = "Project ID cannot be empty."
  }
}

variable "region" {
  description = "GCP region for the subnet (e.g., 'us-central1')"
  type        = string

  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]$", var.region))
    error_message = "Region must be a valid GCP region (e.g., 'us-central1')."
  }
}

variable "company_name" {
  description = "Company/tenant name used in resource naming (e.g., 'company-a', 'common-services')"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.company_name))
    error_message = "Company name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (e.g., 'prod', 'dev', 'staging')"
  type        = string

  validation {
    condition     = contains(["prod", "dev", "staging", "test"], var.environment)
    error_message = "Environment must be one of: prod, dev, staging, test."
  }
}

variable "cidr_range" {
  description = "CIDR range for the subnet (e.g., '10.1.0.0/24'). Ensure this doesn't overlap with other VPCs if you plan to peer them."
  type        = string

  validation {
    condition     = can(cidrhost(var.cidr_range, 0))
    error_message = "CIDR range must be a valid IPv4 CIDR block (e.g., '10.1.0.0/24')."
  }
}

variable "enable_private_google_access" {
  description = "Enable Private Google Access. When true, VMs without external IPs can reach Google APIs (Cloud Storage, BigQuery, etc.)."
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs. Useful for network monitoring, troubleshooting, and security analysis. May incur additional costs."
  type        = bool
  default     = false
}

variable "routing_mode" {
  description = "Network routing mode. REGIONAL = routes learned by Cloud Routers are regional. GLOBAL = routes are global."
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "GLOBAL"], var.routing_mode)
    error_message = "Routing mode must be either REGIONAL or GLOBAL."
  }
}