output "instance_name" { value = google_compute_instance.vm.name }
output "instance_id" { value = google_compute_instance.vm.instance_id }
output "static_ip" { value = var.enable_external_ip ? google_compute_address.static_ip[0].address : null }
output "internal_ip" { value = google_compute_instance.vm.network_interface[0].network_ip }
output "zone" { value = google_compute_instance.vm.zone }
output "service_account_email" { value = google_service_account.vm_sa.email }
output "ssh_command" { 
  value = "gcloud compute ssh ${google_compute_instance.vm.name} --zone=${google_compute_instance.vm.zone} --project=${var.project_id}" 
}