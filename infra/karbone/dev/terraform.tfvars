project_id = "karbone-dev-apps-c2a6"
region     = "us-east4"
zone       = "us-east4-a"

# Networking — reference existing resources from pnl-pipeline
existing_vpc_name    = "karbone-dev-apps-vpc"
existing_router_name = "pnl-router"
app_subnet_cidr      = "10.0.2.0/24"

# VM
vm_machine_type      = "e2-standard-2"
vm_boot_disk_size_gb = 100
vm_boot_disk_type    = "pd-balanced"

# Cloud SQL
db_tier = "db-f1-micro"
# db_password — set via TF_VAR_db_password env var or -var flag, never commit

# IAM
infra_admins_group_email = "karbone-dev-infra-admins@karbone.com"

# Observability
notification_emails = ["alerts-dev@karbone.com"]

# Labels
labels = {
  team         = "karbone-engineering"
  application  = "karbone-hub"
  environment  = "dev"
  company_name = "karbone"
  purpose      = "energy-trading-platform"
  managed_by   = "terraform"
}
