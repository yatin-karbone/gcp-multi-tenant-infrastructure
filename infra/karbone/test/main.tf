# -------------------------------------------------------
# Data sources — reference existing resources
# -------------------------------------------------------

data "google_compute_network" "vpc" {
  name    = var.existing_vpc_name
  project = var.project_id
}

data "google_compute_subnetwork" "karbone_app_subnet" {
  name    = "karbone-app-subnet"
  region  = var.region
  project = var.project_id
}

# -------------------------------------------------------
# App VM
# -------------------------------------------------------

module "karbone_test_vm" {
  source = "../../modules/app-vm"

  project_id         = var.project_id
  region             = var.region
  zone               = var.zone
  company_name       = "karbone"
  environment        = var.environment
  network_id         = data.google_compute_network.vpc.self_link
  subnetwork_id      = data.google_compute_subnetwork.karbone_app_subnet.self_link
  machine_type       = var.vm_machine_type
  boot_disk_size_gb  = var.vm_boot_disk_size_gb
  boot_disk_type     = var.vm_boot_disk_type
  enable_external_ip = true
  # Reuse existing firewall rules from dev (they target the "karbone-app" tag)
  tags               = ["karbone-app"]
  labels             = var.labels
}

# -------------------------------------------------------
# Cloud SQL — standalone test database
# -------------------------------------------------------

module "karbone_test_db" {
  source = "../../modules/cloud-sql"

  project_id          = var.project_id
  region              = var.region
  vpc_id              = data.google_compute_network.vpc.self_link
  instance_name       = "karbone-test-db"
  tier                = var.db_tier
  database_name       = "karbone"
  user_name           = "karbone_app"
  user_password       = var.db_password
  backup_enabled      = true
  pitr_enabled        = false
  deletion_protection = false
  availability_type   = "ZONAL"
  disk_size_gb        = 10
  labels              = var.labels
}

# -------------------------------------------------------
# IAM — test VM service account pulls images from Artifact Registry
# -------------------------------------------------------

resource "google_artifact_registry_repository_iam_member" "test_vm_sa_ar_reader" {
  project    = var.project_id
  location   = var.region
  repository = "karbone"
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${module.karbone_test_vm.service_account_email}"
}

# -------------------------------------------------------
# Secret Manager — store test DB password
# -------------------------------------------------------

resource "google_secret_manager_secret" "test_db_password" {
  project   = var.project_id
  secret_id = "ktc-test-db-password"

  replication {
    auto {}
  }

  labels = var.labels
}

resource "google_secret_manager_secret_iam_member" "test_vm_sa_secret_accessor" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.test_db_password.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.karbone_test_vm.service_account_email}"
}

# -------------------------------------------------------
# IAM — infra admins get OS login + IAP SSH on test VM
# -------------------------------------------------------

resource "google_compute_instance_iam_member" "admins_test_vm_ssh" {
  project       = var.project_id
  zone          = var.zone
  instance_name = module.karbone_test_vm.instance_name
  role          = "roles/compute.osAdminLogin"
  member        = "group:${var.infra_admins_group_email}"
}
