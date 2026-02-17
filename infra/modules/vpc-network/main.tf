/**
 * VPC Network Module
 * 
 * Creates a VPC network with a single subnet for a given environment.
 * Supports private Google access and configurable IP ranges.
 */

# VPC Network
resource "google_compute_network" "vpc" {
  name                    = "${var.company_name}-${var.environment}-vpc"
  auto_create_subnetworks = false
  routing_mode            = var.routing_mode
  project                 = var.project_id

  description = "VPC network for ${var.company_name} ${var.environment} environment"
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.company_name}-${var.environment}-subnet"
  ip_cidr_range = var.cidr_range
  region        = var.region
  network       = google_compute_network.vpc.id
  project       = var.project_id

  private_ip_google_access = var.enable_private_google_access

  # Optional flow logs
  dynamic "log_config" {
    for_each = var.enable_flow_logs ? [1] : []
    content {
      aggregation_interval = "INTERVAL_5_SEC"
      flow_sampling        = 0.5
      metadata             = "INCLUDE_ALL_METADATA"
    }
  }

  description = "Primary subnet for ${var.company_name} ${var.environment} environment"
}

# Cloud Router (for Cloud NAT if needed in the future)
resource "google_compute_router" "router" {
  name    = "${var.company_name}-${var.environment}-router"
  region  = var.region
  network = google_compute_network.vpc.id
  project = var.project_id

  description = "Cloud Router for ${var.company_name} ${var.environment}"
}