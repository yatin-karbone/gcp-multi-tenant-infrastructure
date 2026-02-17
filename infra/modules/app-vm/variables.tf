variable "project_id" { 
  description = "GCP Project ID"
  type = string 
}

variable "region" { 
  description = "GCP region"
  type = string 
}

variable "zone" { 
  description = "GCP zone"
  type = string 
}

variable "company_name" { 
  description = "Company name"
  type = string 
}

variable "environment" { 
  description = "Environment"
  type = string 
}

variable "network_id" { 
  description = "VPC network ID"
  type = string 
}

variable "subnetwork_id" { 
  description = "Subnet ID"
  type = string 
}

variable "machine_type" {
  description = "Machine type"
  type        = string
  default     = "e2-medium"
}

variable "boot_disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 20
}

variable "boot_disk_type" {
  description = "Boot disk type"
  type        = string
  default     = "pd-standard"
}

variable "image" {
  description = "Boot image"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
}

variable "enable_external_ip" {
  description = "Assign external IP"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Network tags"
  type        = list(string)
  default     = ["ssh-enabled", "web-server"]
}

variable "metadata_startup_script" {
  description = "Startup script"
  type        = string
  default     = ""
}