# -------------------------------------------------------
# Data sources — reference existing resources from pnl-pipeline
# -------------------------------------------------------

data "google_compute_network" "vpc" {
  name    = var.existing_vpc_name
  project = var.project_id
}

data "google_compute_router" "router" {
  name    = var.existing_router_name
  region  = var.region
  project = var.project_id
}

# -------------------------------------------------------
# Enable required APIs
# -------------------------------------------------------

resource "google_project_service" "enabled_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "iam.googleapis.com",
    "secretmanager.googleapis.com",
    "sqladmin.googleapis.com",
    "servicenetworking.googleapis.com",
  ])

  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}

# -------------------------------------------------------
# Subnet for Karbone app
# -------------------------------------------------------

resource "google_compute_subnetwork" "karbone_app_subnet" {
  name                     = "karbone-app-subnet"
  ip_cidr_range            = var.app_subnet_cidr
  region                   = var.region
  network                  = data.google_compute_network.vpc.id
  private_ip_google_access = true
}

# -------------------------------------------------------
# Firewall rules
# -------------------------------------------------------

resource "google_compute_firewall" "allow_http" {
  name    = "karbone-app-allow-http"
  network = data.google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["karbone-app"]
}

resource "google_compute_firewall" "allow_https" {
  name    = "karbone-app-allow-https"
  network = data.google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["karbone-app"]
}

resource "google_compute_firewall" "allow_internal" {
  name    = "karbone-app-allow-internal"
  network = data.google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.0.0.0/8"]
  target_tags   = ["karbone-app"]
}

# -------------------------------------------------------
# Cloud NAT (dedicated static IP for Karbone)
# -------------------------------------------------------

module "karbone_nat" {
  source = "../../modules/cloud-nat"

  project_id        = var.project_id
  region            = var.region
  router_name       = data.google_compute_router.router.name
  nat_name          = "karbone-app-nat"
  static_ip_name    = "karbone-app-nat-ip"
  subnet_self_links = [google_compute_subnetwork.karbone_app_subnet.self_link]
}

# -------------------------------------------------------
# App VM (module creates its own service account)
# -------------------------------------------------------

module "karbone_vm" {
  source = "../../modules/app-vm"

  project_id        = var.project_id
  region            = var.region
  zone              = var.zone
  company_name      = "karbone"
  environment       = var.environment
  network_id        = data.google_compute_network.vpc.self_link
  subnetwork_id     = google_compute_subnetwork.karbone_app_subnet.self_link
  machine_type      = var.vm_machine_type
  boot_disk_size_gb = var.vm_boot_disk_size_gb
  boot_disk_type    = var.vm_boot_disk_type
  enable_external_ip = true
  tags              = ["karbone-app"]
  labels            = var.labels
}

# -------------------------------------------------------
# Additional IAM for the VM service account
# (logging/monitoring already handled by app-vm module)
# -------------------------------------------------------

resource "google_project_iam_member" "karbone_sa_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${module.karbone_vm.service_account_email}"
}

# -------------------------------------------------------
# IAM — Admin group
# -------------------------------------------------------

locals {
  admin_roles = [
    "roles/compute.instanceAdmin.v1",
    "roles/compute.osAdminLogin",
    "roles/iap.tunnelResourceAccessor",
    "roles/viewer",
    "roles/storage.admin",
    "roles/logging.admin",
    "roles/monitoring.admin",
  ]
}

resource "google_project_iam_member" "infra_admins" {
  for_each = toset(local.admin_roles)

  project = var.project_id
  role    = each.value
  member  = "group:${var.infra_admins_group_email}"
}

# -------------------------------------------------------
# Cloud SQL (PostgreSQL 15 + PostGIS)
# -------------------------------------------------------

module "karbone_db" {
  source = "../../modules/cloud-sql"

  project_id          = var.project_id
  region              = var.region
  vpc_id              = data.google_compute_network.vpc.self_link
  instance_name       = "karbone-dev-db"
  tier                = var.db_tier
  database_name       = "karbone"
  user_name           = "karbone_app"
  user_password       = var.db_password
  backup_enabled      = true
  pitr_enabled        = true
  deletion_protection = false
  availability_type   = "ZONAL"
  disk_size_gb        = 10
  labels              = var.labels

  depends_on = [google_project_service.enabled_apis]
}

# -------------------------------------------------------
# Secret Manager — GitLab PAT access for VM service account
# -------------------------------------------------------

data "google_secret_manager_secret" "gitlab_pat" {
  secret_id = "karbone-gitlab-pat"
  project   = var.project_id
}

resource "google_secret_manager_secret_iam_member" "karbone_sa_gitlab_access" {
  secret_id = data.google_secret_manager_secret.gitlab_pat.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.karbone_vm.service_account_email}"
}

# -------------------------------------------------------
# GCS bucket for DB backups (migration + ongoing)
# -------------------------------------------------------

resource "google_storage_bucket" "db_backups" {
  name          = "${var.project_id}-karbone-db-backups"
  location      = var.region
  project       = var.project_id
  force_destroy = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 30
    }
  }

  labels = var.labels
}

resource "google_storage_bucket_iam_member" "karbone_sa_backup_access" {
  bucket = google_storage_bucket.db_backups.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${module.karbone_vm.service_account_email}"
}
