# ============================================
# NETWORK OUTPUTS
# ============================================

output "vpc_name" {
  description = "VPC network name"
  value       = module.vpc.network_name
}

output "subnet_name" {
  description = "Subnet name"
  value       = module.vpc.subnetwork_name
}

output "subnet_cidr" {
  description = "Subnet CIDR range"
  value       = module.vpc.subnetwork_cidr
}

# ============================================
# VM OUTPUTS
# ============================================

output "vm_name" {
  description = "Application VM name"
  value       = module.app_vm.instance_name
}

output "vm_external_ip" {
  description = "External IP address (add this to DNS A record)"
  value       = module.app_vm.static_ip
}

output "vm_internal_ip" {
  description = "Internal IP address"
  value       = module.app_vm.internal_ip
}

output "vm_zone" {
  description = "VM zone"
  value       = module.app_vm.zone
}

# ============================================
# SSH ACCESS
# ============================================

output "ssh_command" {
  description = "SSH command for infrastructure admins and developers"
  value       = module.app_vm.ssh_command
}

# ============================================
# DNS CONFIGURATION
# ============================================

output "dns_configuration" {
  description = "DNS A record to create"
  value = <<-EOT
  
  ========================================
  DNS CONFIGURATION
  ========================================
  
  Create the following DNS A record:
  
  Name:  ${var.application_domain != "" ? var.application_domain : "app.noreva.ai"}
  Type:  A
  Value: ${module.app_vm.static_ip}
  TTL:   300
  
  ========================================
  EOT
}

# ============================================
# STORAGE OUTPUTS
# ============================================

output "uploads_bucket" {
  description = "GCS bucket for uploads backup"
  value       = var.create_backup_bucket ? google_storage_bucket.app_uploads[0].name : null
}

output "backups_bucket" {
  description = "GCS bucket for database backups"
  value       = var.create_backup_bucket ? google_storage_bucket.db_backups[0].name : null
}

# ============================================
# SERVICE ACCOUNT
# ============================================

output "vm_service_account_email" {
  description = "VM service account email"
  value       = module.app_vm.service_account_email
}

# ============================================
# DEPLOYMENT INSTRUCTIONS
# ============================================

output "next_steps" {
  description = "Next steps after Terraform deployment"
  value = <<-EOT
  
  ========================================
  DEPLOYMENT SUCCESSFUL
  ========================================
  
  VM Created: ${module.app_vm.instance_name}
  External IP: ${module.app_vm.static_ip}
  
  NEXT STEPS:
  
  1. SSH to the VM:
     ${module.app_vm.ssh_command}
  
  2. Install Docker manually (startup script available in scripts/startup.sh)
  
  3. Upload your docker-compose.yaml to /opt/app/
  
  4. Start your application
  
  ========================================
  EOT
}