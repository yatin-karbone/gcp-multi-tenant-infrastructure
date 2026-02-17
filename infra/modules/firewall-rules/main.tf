/**
 * Firewall Rules Module
 * 
 * Creates standard firewall rules for a VPC:
 * - SSH access (configurable source ranges)
 * - HTTP/HTTPS traffic
 * - Internal VPC traffic
 * - ICMP (ping)
 */

# SSH Access
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.company_name}-${var.environment}-allow-ssh"
  network = var.network_id
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.allow_ssh_from_anywhere ? ["0.0.0.0/0"] : var.allowed_ssh_ranges
  target_tags   = ["ssh-enabled"]

  description = "Allow SSH access to instances with 'ssh-enabled' tag"
  priority    = 1000
}

# HTTP and HTTPS
resource "google_compute_firewall" "allow_web" {
  count = var.allow_http_https ? 1 : 0

  name    = "${var.company_name}-${var.environment}-allow-web"
  network = var.network_id
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]

  description = "Allow HTTP and HTTPS traffic to instances with 'web-server' tag"
  priority    = 1000
}

# Internal VPC Traffic
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.company_name}-${var.environment}-allow-internal"
  network = var.network_id
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = var.internal_ranges

  description = "Allow all internal traffic within the VPC"
  priority    = 1000
}

# ICMP (Ping) from anywhere
resource "google_compute_firewall" "allow_icmp" {
  name    = "${var.company_name}-${var.environment}-allow-icmp"
  network = var.network_id
  project = var.project_id

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]

  description = "Allow ICMP (ping) from anywhere"
  priority    = 1000
}

# Custom ports (optional)
resource "google_compute_firewall" "custom_ports" {
  for_each = { for idx, rule in var.custom_ports : idx => rule }

  name    = "${var.company_name}-${var.environment}-allow-custom-${each.key}"
  network = var.network_id
  project = var.project_id

  allow {
    protocol = each.value.protocol
    ports    = each.value.ports
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["custom-port-${each.key}"]

  description = "Custom firewall rule for ${each.value.protocol} ports ${join(",", each.value.ports)}"
  priority    = 1000
}