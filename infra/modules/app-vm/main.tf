# Service Account for the VM
resource "google_service_account" "vm_sa" {
  account_id   = "${var.company_name}-${var.environment}-sa"
  display_name = "VM Service Account for ${var.company_name} ${var.environment}"
  project      = var.project_id
}

# Basic Logging/Monitoring permissions
resource "google_project_iam_member" "logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.vm_sa.email}"
}

resource "google_project_iam_member" "monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.vm_sa.email}"
}

# Static IP
resource "google_compute_address" "static_ip" {
  count   = var.enable_external_ip ? 1 : 0
  name    = "${var.company_name}-${var.environment}-ip"
  region  = var.region
  project = var.project_id
}

# VM Instance
resource "google_compute_instance" "vm" {
  name         = "${var.company_name}-${var.environment}-vm"
  machine_type = var.machine_type
  zone         = var.zone
  project      = var.project_id
  
  tags = var.tags
  labels = var.labels

  boot_disk {
    initialize_params {
      image = var.image
      size  = var.boot_disk_size_gb
      type  = var.boot_disk_type
    }
  }

  network_interface {
    network    = var.network_id
    subnetwork = var.subnetwork_id

    dynamic "access_config" {
      for_each = var.enable_external_ip ? [1] : []
      content {
        nat_ip = google_compute_address.static_ip[0].address
      }
    }
  }

  service_account {
    email  = google_service_account.vm_sa.email
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = var.metadata_startup_script

  metadata = {
    enable-oslogin = "TRUE"
  }

  lifecycle {
    ignore_changes = [
      boot_disk[0].initialize_params[0].image,
      metadata_startup_script,
    ]
  }
}