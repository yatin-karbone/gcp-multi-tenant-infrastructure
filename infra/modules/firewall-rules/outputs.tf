output "ssh_firewall_name" {
  description = "Name of the SSH firewall rule"
  value       = google_compute_firewall.allow_ssh.name
}

output "ssh_firewall_id" {
  description = "ID of the SSH firewall rule"
  value       = google_compute_firewall.allow_ssh.id
}

output "web_firewall_name" {
  description = "Name of the HTTP/HTTPS firewall rule (if enabled)"
  value       = var.allow_http_https ? google_compute_firewall.allow_web[0].name : null
}

output "internal_firewall_name" {
  description = "Name of the internal traffic firewall rule"
  value       = google_compute_firewall.allow_internal.name
}

output "icmp_firewall_name" {
  description = "Name of the ICMP firewall rule"
  value       = google_compute_firewall.allow_icmp.name
}