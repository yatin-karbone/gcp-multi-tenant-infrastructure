project_id = "karbone-prod-apps-0f22"

region = "us-east4"
zone   = "us-east4-c"

# Networking — prod creates its own VPC
vpc_cidr_range = "10.1.0.0/24"

# Office IPs allowed to access HTTPS (port 443). Port 80 stays open for ACME challenges.
office_allowed_ips = [
  "38.142.253.146/32", # Karbone office
  "24.44.9.107/32",    # Yatin home
]

# VM
vm_machine_type      = "e2-standard-2"
vm_boot_disk_size_gb = 100
vm_boot_disk_type    = "pd-balanced"

# Cloud SQL
db_tier = "db-g1-small"
# db_password — set via TF_VAR_db_password env var or -var flag, never commit

# GitHub Actions — WIF scope (owner/repo)
github_repo = "Karbone-org/karbone-trade-capture"

# IAM
infra_admins_group_email            = "infra-admins@karbone.com"
external_developers_group_email     = "karbone-prod-external@karbone.com"

# Observability
notification_emails = ["karbone-alerts-prod@karbone.com"]
log_retention_days  = 30

# Labels
labels = {
  team         = "karbone-engineering"
  application  = "karbone-hub"
  environment  = "prod"
  company_name = "karbone"
  purpose      = "energy-trading-platform"
  managed_by   = "terraform"
}
