# Reserve a private IP range for Cloud SQL VPC peering
resource "google_compute_global_address" "private_ip_range" {
  name          = "${var.instance_name}-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = var.vpc_id
  project       = var.project_id
}

# Create the VPC peering connection for private services access
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = var.vpc_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}

# Cloud SQL PostgreSQL instance
resource "google_sql_database_instance" "instance" {
  name             = var.instance_name
  database_version = var.db_version
  region           = var.region
  project          = var.project_id

  deletion_protection = var.deletion_protection

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier              = var.tier
    availability_type = var.availability_type
    disk_size         = var.disk_size_gb
    disk_autoresize   = var.disk_autoresize

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = var.vpc_id
      enable_private_path_for_google_cloud_services = true
    }

    backup_configuration {
      enabled                        = var.backup_enabled
      point_in_time_recovery_enabled = var.pitr_enabled
      transaction_log_retention_days = var.backup_retention_days
      backup_retention_settings {
        retained_backups = var.backup_retention_days
      }
    }

    maintenance_window {
      day  = 7 # Sunday
      hour = 4 # 4 AM UTC
    }

    database_flags {
      name  = "cloudsql.iam_authentication"
      value = "on"
    }

    user_labels = var.labels
  }
}

# Application database
resource "google_sql_database" "database" {
  name     = var.database_name
  instance = google_sql_database_instance.instance.name
  project  = var.project_id
}

# Application user
resource "google_sql_user" "user" {
  name     = var.user_name
  instance = google_sql_database_instance.instance.name
  password = var.user_password
  project  = var.project_id
}
