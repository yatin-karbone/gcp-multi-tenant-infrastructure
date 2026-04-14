output "nat_ip" {
  value       = google_compute_address.nat_ip.address
  description = "Static external IP for NAT — use for IP whitelisting"
}

output "nat_name" {
  value       = google_compute_router_nat.nat.name
  description = "NAT gateway name"
}
