output "vm_static_ip" {
  value       = module.karbone_test_vm.static_ip
  description = "External IP — add as A record for ktc-test.karbone.com in GoDaddy"
}

output "vm_internal_ip" {
  value       = module.karbone_test_vm.internal_ip
  description = "Internal IP of the test VM"
}

output "vm_ssh_command" {
  value       = "gcloud compute ssh karbone-test-vm --tunnel-through-iap --zone=us-east4-c --project=karbone-dev-apps-c2a6"
  description = "IAP SSH command for the test VM"
}

output "cloud_sql_private_ip" {
  value       = module.karbone_test_db.private_ip
  description = "Private IP for DJANGO_DB_URL on the test VM"
}

output "cloud_sql_connection_name" {
  value       = module.karbone_test_db.instance_connection_name
  description = "Cloud SQL connection name"
}

output "service_account_email" {
  value       = module.karbone_test_vm.service_account_email
  description = "Test VM service account email"
}
