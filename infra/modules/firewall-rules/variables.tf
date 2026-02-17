variable "project_id" {
  description = "GCP Project ID where firewall rules will be created"
  type        = string

  validation {
    condition     = length(var.project_id) > 0
    error_message = "Project ID cannot be empty."
  }
}

variable "network_id" {
  description = "VPC network ID from vpc-network module (e.g., module.vpc.network_id)"
  type        = string

  validation {
    condition     = length(var.network_id) > 0
    error_message = "Network ID cannot be empty."
  }
}

variable "company_name" {
  description = "Company/tenant name used in resource naming"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.company_name))
    error_message = "Company name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (prod, dev, staging, test)"
  type        = string

  validation {
    condition     = contains(["prod", "dev", "staging", "test"], var.environment)
    error_message = "Environment must be one of: prod, dev, staging, test."
  }
}

variable "allow_ssh_from_anywhere" {
  description = "Allow SSH from any IP (0.0.0.0/0). For production, consider setting to false and specifying allowed_ssh_ranges."
  type        = bool
  default     = true
}

variable "allowed_ssh_ranges" {
  description = "IP CIDR ranges allowed to SSH. Only used if allow_ssh_from_anywhere is false. Example: ['203.0.113.0/24', '198.51.100.0/24']"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.allowed_ssh_ranges : can(cidrhost(cidr, 0))])
    error_message = "All SSH ranges must be valid CIDR blocks."
  }
}

variable "allow_http_https" {
  description = "Create firewall rules for HTTP (80) and HTTPS (443) traffic"
  type        = bool
  default     = true
}

variable "internal_ranges" {
  description = "Internal IP CIDR ranges for internal traffic rule. Default allows all RFC1918 private networks."
  type        = list(string)
  default     = ["10.0.0.0/8"]

  validation {
    condition     = alltrue([for cidr in var.internal_ranges : can(cidrhost(cidr, 0))])
    error_message = "All internal ranges must be valid CIDR blocks."
  }
}

variable "custom_ports" {
  description = "Additional custom ports to allow. Example: [{protocol='tcp', ports=['8080', '9090']}]"
  type = list(object({
    protocol = string
    ports    = list(string)
  }))
  default = []
}