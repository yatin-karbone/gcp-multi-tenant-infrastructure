# -------------------------------------------------------
# Enable required APIs
# -------------------------------------------------------

resource "google_project_service" "enabled_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "secretmanager.googleapis.com",
    "sqladmin.googleapis.com",
    "servicenetworking.googleapis.com",
    "artifactregistry.googleapis.com",
    "sts.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iap.googleapis.com",
  ])

  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}

# -------------------------------------------------------
# VPC (prod creates its own)
# -------------------------------------------------------

module "karbone_vpc" {
  source = "../../modules/vpc-network"

  project_id   = var.project_id
  region       = var.region
  company_name = "karbone"
  environment  = var.environment
  cidr_range   = var.vpc_cidr_range

  depends_on = [google_project_service.enabled_apis]
}

# -------------------------------------------------------
# Firewall rules
# -------------------------------------------------------

resource "google_compute_firewall" "allow_http" {
  name    = "karbone-app-allow-http"
  network = module.karbone_vpc.network_name
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
  network = module.karbone_vpc.network_name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = var.office_allowed_ips
  target_tags   = ["karbone-app"]
}

resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "karbone-app-allow-iap-ssh"
  network = module.karbone_vpc.network_name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["karbone-app"]
}

resource "google_compute_firewall" "allow_internal" {
  name    = "karbone-app-allow-internal"
  network = module.karbone_vpc.network_name
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
  router_name       = module.karbone_vpc.router_name
  nat_name          = "karbone-app-nat"
  static_ip_name    = "karbone-app-nat-ip"
  subnet_self_links = [module.karbone_vpc.subnetwork_self_link]
}

# -------------------------------------------------------
# App VM (module creates its own service account)
# -------------------------------------------------------

module "karbone_vm" {
  source = "../../modules/app-vm"

  project_id         = var.project_id
  region             = var.region
  zone               = var.zone
  company_name       = "karbone"
  environment        = var.environment
  network_id         = module.karbone_vpc.network_self_link
  subnetwork_id      = module.karbone_vpc.subnetwork_self_link
  machine_type       = var.vm_machine_type
  boot_disk_size_gb  = var.vm_boot_disk_size_gb
  boot_disk_type     = var.vm_boot_disk_type
  enable_external_ip = true
  tags               = ["karbone-app"]
  labels             = var.labels

  metadata_startup_script = <<-EOF
    #!/bin/bash
    # Configure Ops Agent to collect Docker container logs with severity promotion
    cat > /etc/google-cloud-ops-agent/config.yaml << 'OPS_AGENT_CONFIG'
    logging:
      receivers:
        docker_containers:
          type: files
          include_paths:
            - /var/lib/docker/containers/*/*.log
          record_log_file_path: true
      processors:
        parse_docker_json:
          type: parse_json
          field: message
          time_key: time
          time_format: "%Y-%m-%dT%H:%M:%S.%fZ"
        parse_app_json:
          type: parse_json
          field: log
        set_severity:
          type: modify_fields
          fields:
            severity:
              move_from: jsonPayload.severity
      service:
        pipelines:
          docker_pipeline:
            receivers: [docker_containers]
            processors: [parse_docker_json, parse_app_json, set_severity]
            exporters: [google_cloud_logging]
    OPS_AGENT_CONFIG
    systemctl restart google-cloud-ops-agent
  EOF
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

  external_developer_roles = [
    "roles/viewer",
    "roles/logging.viewer",
    "roles/monitoring.viewer",
    "roles/iap.tunnelResourceAccessor",
  ]
}

resource "google_project_iam_member" "infra_admins" {
  for_each = toset(local.admin_roles)

  project = var.project_id
  role    = each.value
  member  = "group:${var.infra_admins_group_email}"
}

resource "google_project_iam_member" "external_developers" {
  for_each = toset(local.external_developer_roles)

  project = var.project_id
  role    = each.value
  member  = "group:${var.external_developers_group_email}"
}

resource "google_compute_instance_iam_member" "external_developers_ssh" {
  project       = var.project_id
  zone          = var.zone
  instance_name = module.karbone_vm.instance_name
  role          = "roles/compute.osAdminLogin"
  member        = "group:${var.external_developers_group_email}"
}

resource "google_service_account_iam_member" "external_developers_vm_sa_user" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${module.karbone_vm.service_account_email}"
  role               = "roles/iam.serviceAccountUser"
  member             = "group:${var.external_developers_group_email}"
}

# -------------------------------------------------------
# Cloud SQL (PostgreSQL 15 + PostGIS)
# -------------------------------------------------------

module "karbone_db" {
  source = "../../modules/cloud-sql"

  project_id          = var.project_id
  region              = var.region
  vpc_id              = module.karbone_vpc.network_self_link
  instance_name       = "karbone-prod-db"
  tier                = var.db_tier
  database_name       = "karbone"
  user_name           = "karbone_app"
  user_password       = var.db_password
  backup_enabled      = true
  pitr_enabled        = true
  deletion_protection = true
  availability_type   = "ZONAL"
  disk_size_gb        = 20
  labels              = var.labels

  depends_on = [google_project_service.enabled_apis]
}

# -------------------------------------------------------
# Secret Manager — GitHub PAT access for VM service account
# -------------------------------------------------------

data "google_secret_manager_secret" "github_pat" {
  secret_id = "ktc-github-pat"
  project   = var.project_id
}

resource "google_secret_manager_secret_iam_member" "karbone_sa_github_access" {
  secret_id = data.google_secret_manager_secret.github_pat.id
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

# -------------------------------------------------------
# Artifact Registry — Docker registry for CI/CD images
# -------------------------------------------------------

resource "google_artifact_registry_repository" "karbone" {
  project       = var.project_id
  location      = var.region
  repository_id = "karbone"
  description   = "Karbone Docker images"
  format        = "DOCKER"

  depends_on = [google_project_service.enabled_apis]
}

# VM service account needs read access to pull images
resource "google_artifact_registry_repository_iam_member" "karbone_sa_ar_reader" {
  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.karbone.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${module.karbone_vm.service_account_email}"
}

# -------------------------------------------------------
# Workload Identity Federation — GitHub Actions
# -------------------------------------------------------

resource "google_iam_workload_identity_pool" "github_actions" {
  project                   = var.project_id
  workload_identity_pool_id = "github-actions"
  display_name              = "GitHub Actions"
  description               = "WIF pool for GitHub Actions CI/CD"

  depends_on = [google_project_service.enabled_apis]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_actions.workload_identity_pool_id
  workload_identity_pool_provider_id = "github"
  display_name                       = "GitHub OIDC"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  # Only tokens from this specific GitHub repo are accepted
  attribute_condition = "assertion.repository == '${var.github_repo}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Allow GitHub Actions to impersonate the VM service account (write to Artifact Registry)
resource "google_service_account_iam_member" "github_actions_wif" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${module.karbone_vm.service_account_email}"
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_actions.name}/attribute.repository/${var.github_repo}"
}

# Grant the VM service account permission to push images (used by GitHub Actions via impersonation)
resource "google_artifact_registry_repository_iam_member" "karbone_sa_ar_writer" {
  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.karbone.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${module.karbone_vm.service_account_email}"
}

# -------------------------------------------------------
# IAM — GitHub Actions deploy (SSH to VM via IAP)
# -------------------------------------------------------

resource "google_project_iam_member" "karbone_sa_os_login" {
  project = var.project_id
  role    = "roles/compute.osAdminLogin"
  member  = "serviceAccount:${module.karbone_vm.service_account_email}"
}

resource "google_project_iam_member" "karbone_sa_iap_tunnel" {
  project = var.project_id
  role    = "roles/iap.tunnelResourceAccessor"
  member  = "serviceAccount:${module.karbone_vm.service_account_email}"
}

# Required for gcloud compute ssh via OS Login — SA must be able to act as itself
resource "google_service_account_iam_member" "karbone_sa_act_as_self" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${module.karbone_vm.service_account_email}"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${module.karbone_vm.service_account_email}"
}

# -------------------------------------------------------
# Observability (monitoring from day 1)
# -------------------------------------------------------

module "observability" {
  source = "../../modules/observability"

  project_id           = var.project_id
  region               = var.region
  company_name         = "karbone"
  environment          = var.environment
  notification_emails  = var.notification_emails
  disk_alert_threshold = 80
  log_retention_days   = var.log_retention_days
  enable_error_alerts  = true
  use_severity_filter  = true
}


resource "google_monitoring_alert_policy" "cpu_usage" {
  display_name = "karbone-prod-cpu-usage-high"
  combiner     = "OR"
  project      = var.project_id

  conditions {
    display_name = "CPU utilization above 90%"
    condition_threshold {
      filter          = "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/cpu/utilization\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.9
      duration        = "300s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = module.observability.notification_channel_ids
}
