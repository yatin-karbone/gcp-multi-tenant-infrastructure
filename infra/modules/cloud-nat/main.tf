# Reserve a static external IP for NAT (used for IP whitelisting)
resource "google_compute_address" "nat_ip" {
  name    = var.static_ip_name
  region  = var.region
  project = var.project_id
}

# Cloud NAT gateway with dedicated static IP
resource "google_compute_router_nat" "nat" {
  name                               = var.nat_name
  router                             = var.router_name
  region                             = var.region
  project                            = var.project_id
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [google_compute_address.nat_ip.self_link]
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  dynamic "subnetwork" {
    for_each = var.subnet_self_links
    content {
      name                    = subnetwork.value
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    }
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
