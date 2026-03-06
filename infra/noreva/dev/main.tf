/**
 * Noreva Development Infrastructure
 *
 * Deploys a development environment.
 */

# Local values
locals {
  company_name = "noreva"
  environment  = "dev"
}

# ============================================
# IAM - Groups and Permissions
# ============================================

# Define standard role sets
locals {
  infra_admin_roles = [
    "roles/compute.networkAdmin",
    "roles/compute.instanceAdmin.v1",
    "roles/compute.securityAdmin",
    "roles/compute.osAdminLogin",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.serviceAccountUser",
    "roles/resourcemanager.projectIamAdmin",
    "roles/viewer",
    "roles/storage.admin",
    "roles/logging.admin",
    "roles/monitoring.admin",
    "roles/iap.tunnelResourceAccessor"
  ]

  external_developer_roles = [
    "roles/viewer",
    "roles/logging.viewer",
    "roles/monitoring.viewer",
    "roles/iam.serviceAccountUser",
    "roles/iap.tunnelResourceAccessor",
  ]
}

module "project_iam" {
  source = "../../modules/project-iam"

  project_id = var.project_id

  group_iam_bindings = {
    (var.infra_admins_group_email)        = local.infra_admin_roles
    (var.external_developers_group_email) = local.external_developer_roles
  }
}

# ============================================
# Networking - VPC, Subnet, Firewall
# ============================================

module "vpc" {
  source = "../../modules/vpc-network"

  project_id   = var.project_id
  region       = var.region
  company_name = local.company_name
  environment  = local.environment
  cidr_range   = var.vpc_cidr_range

  enable_private_google_access = true
  enable_flow_logs             = false
  routing_mode                 = "REGIONAL"
}

module "firewall" {
  source = "../../modules/firewall-rules"

  project_id   = var.project_id
  network_id   = module.vpc.network_id
  company_name = local.company_name
  environment  = local.environment

  allow_ssh_from_anywhere = var.allow_ssh_from_anywhere
  allowed_ssh_ranges      = var.allowed_ssh_ranges
  allow_http_https        = true
}

# ============================================
# Compute - Application VM
# ============================================

module "app_vm" {
  source = "../../modules/app-vm"

  labels = {
    environment = local.environment
    company     = local.company_name
    app         = "noreva-hub-dev"
    managed_by  = "terraform"
    purpose     = "development-testing"
  }

  project_id     = var.project_id
  zone           = var.zone
  region         = var.region
  company_name   = local.company_name
  environment    = local.environment
  network_id     = module.vpc.network_id
  subnetwork_id  = module.vpc.subnetwork_id

  # VM Specs (Use smaller machine type for Dev)
  machine_type      = var.vm_machine_type
  boot_disk_size_gb = var.vm_boot_disk_size_gb
  boot_disk_type    = var.vm_boot_disk_type

  # Ubuntu 24.04 LTS
  image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"

  enable_external_ip = true

  tags = ["ssh-enabled", "web-server"]

  # NO STARTUP SCRIPT - will install Docker manually
  metadata_startup_script = ""
}

# ============================================
# Instance-Level IAM - SSH Access
# ============================================

resource "google_compute_instance_iam_member" "dev_ssh_access" {
  project       = var.project_id
  zone          = module.app_vm.zone
  instance_name = module.app_vm.instance_name
  role          = "roles/compute.osAdminLogin"
  member        = "group:${var.external_developers_group_email}"
}

# ============================================
# Cloud Storage - Persistent Data Backups
# ============================================

resource "google_storage_bucket" "app_uploads" {
  count = var.create_backup_bucket ? 1 : 0

  name          = "${var.project_id}-dev-app-uploads"
  location      = var.region
  project       = var.project_id

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 30 # Shorter retention for Dev
    }
  }

  labels = {
    environment = local.environment
    company     = local.company_name
    purpose     = "app-uploads-dev-noreva-hub"
  }
}

resource "google_storage_bucket" "db_backups" {
  count = var.create_backup_bucket ? 1 : 0

  name          = "${var.project_id}-dev-db-backups"
  location      = var.region
  project       = var.project_id

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 14 # Shorter retention for Dev
    }
  }

  labels = {
    environment = local.environment
    company     = local.company_name
    purpose     = "db-backups-dev-noreva-hub"
  }
}

resource "google_storage_bucket_iam_member" "vm_uploads_access" {
  count = var.create_backup_bucket ? 1 : 0

  bucket = google_storage_bucket.app_uploads[0].name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${module.app_vm.service_account_email}"
}

resource "google_storage_bucket_iam_member" "vm_backups_access" {
  count = var.create_backup_bucket ? 1 : 0

  bucket = google_storage_bucket.db_backups[0].name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${module.app_vm.service_account_email}"
}

# ============================================
# Observability - Logging & Alerts
# ============================================

module "observability" {
  source = "../../modules/observability"

  project_id   = var.project_id
  region       = var.region
  company_name = local.company_name
  environment  = local.environment

  notification_emails  = var.notification_emails
  disk_alert_threshold = 80
  log_retention_days   = var.log_retention_days
  enable_error_alerts  = false
}
