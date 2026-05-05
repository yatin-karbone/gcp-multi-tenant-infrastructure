project_id        = "karbone-dev-apps-c2a6"
region            = "us-east4"
zone              = "us-east4-c"
existing_vpc_name = "karbone-dev-apps-vpc"

office_allowed_ips = [
  "38.142.253.146/32",
  "24.44.9.107/32",
]

vm_machine_type      = "e2-standard-2"
vm_boot_disk_size_gb = 100
vm_boot_disk_type    = "pd-balanced"

db_tier = "db-f1-micro"

infra_admins_group_email = "infra-admins@karbone.com"

labels = {
  team         = "karbone-engineering"
  application  = "karbone-hub"
  environment  = "test"
  company_name = "karbone"
  purpose      = "energy-trading-platform"
  managed_by   = "terraform"
}
