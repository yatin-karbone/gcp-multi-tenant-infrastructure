output "vm_static_ip" {
  value       = module.karbone_vm.static_ip
  description = "VM external IP — point DNS A record here"
}

output "vm_internal_ip" {
  value       = module.karbone_vm.internal_ip
  description = "VM internal IP"
}

output "vm_ssh_command" {
  value       = module.karbone_vm.ssh_command
  description = "SSH command via IAP"
}

output "cloud_sql_private_ip" {
  value       = module.karbone_db.private_ip
  description = "Cloud SQL private IP — use in DJANGO_DB_URL"
}

output "cloud_sql_connection_name" {
  value       = module.karbone_db.instance_connection_name
  description = "Cloud SQL connection name"
}

output "nat_external_ip" {
  value       = module.karbone_nat.nat_ip
  description = "NAT static IP — whitelist at NetSuite"
}

output "db_backup_bucket" {
  value       = google_storage_bucket.db_backups.name
  description = "GCS bucket for database backups"
}

output "service_account_email" {
  value       = module.karbone_vm.service_account_email
  description = "Karbone VM service account email"
}
