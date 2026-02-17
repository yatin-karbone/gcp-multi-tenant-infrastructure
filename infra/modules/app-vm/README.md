# Application VM Module

Creates a GCP Compute Engine VM instance with optional static IP, service account, and OS Login.

## Usage

### Basic VM
```hcl
module "app_vm" {
  source = "../../modules/app-vm"
  
  project_id     = "my-project-123456"
  zone           = "us-central1-a"
  region         = "us-central1"
  company_name   = "company-a"
  environment    = "prod"
  network_id     = module.vpc.network_id
  subnetwork_id  = module.vpc.subnetwork_id
}
```

### Production VM (larger, SSD)
```hcl
module "app_vm" {
  source = "../../modules/app-vm"
  
  project_id        = "my-project-123456"
  zone              = "us-central1-a"
  region            = "us-central1"
  company_name      = "company-a"
  environment       = "prod"
  network_id        = module.vpc.network_id
  subnetwork_id     = module.vpc.subnetwork_id
  
  machine_type      = "n2-standard-4"
  boot_disk_size_gb = 50
  boot_disk_type    = "pd-ssd"
}
```

### VM with Startup Script
```hcl
module "app_vm" {
  source = "../../modules/app-vm"
  
  # ... other config ...
  
  metadata_startup_script = file("${path.module}/scripts/startup.sh")
}
```

### VM without External IP (using Cloud NAT)
```hcl
module "app_vm" {
  source = "../../modules/app-vm"
  
  # ... other config ...
  
  enable_external_ip = false
}
```

## Service Account

The module creates a service account for the VM with:
- `roles/logging.logWriter` - Write logs to Cloud Logging
- `roles/monitoring.metricWriter` - Write metrics to Cloud Monitoring

Grant additional permissions as needed:
```hcl
resource "google_project_iam_member" "vm_storage_access" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${module.app_vm.service_account_email}"
}
```

## SSH Access

After creating the VM, grant instance-level SSH access:
```hcl
resource "google_compute_instance_iam_member" "dev_ssh" {
  project       = var.project_id
  zone          = module.app_vm.zone
  instance_name = module.app_vm.instance_name
  role          = "roles/compute.osLoginAdmin"  # With sudo
  member        = "group:developers@example.com"
}
```

## Machine Types

Common machine types:
- `e2-micro` - 0.25-2 vCPU, 1 GB RAM (free tier eligible)
- `e2-small` - 0.5-2 vCPU, 2 GB RAM
- `e2-medium` - 1-2 vCPU, 4 GB RAM (default)
- `e2-standard-2` - 2 vCPU, 8 GB RAM
- `n2-standard-4` - 4 vCPU, 16 GB RAM

See all: https://cloud.google.com/compute/docs/machine-types

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_id | GCP Project ID | string | - | yes |
| zone | GCP zone | string | - | yes |
| region | GCP region | string | - | yes |
| company_name | Company name | string | - | yes |
| environment | Environment | string | - | yes |
| network_id | VPC network ID | string | - | yes |
| subnetwork_id | Subnet ID | string | - | yes |
| machine_type | Machine type | string | "e2-medium" | no |
| boot_disk_size_gb | Disk size (GB) | number | 20 | no |
| boot_disk_type | Disk type | string | "pd-standard" | no |
| image | Boot image | string | "debian-cloud/debian-12" | no |
| enable_external_ip | Assign external IP | bool | true | no |
| tags | Network tags | list(string) | ["ssh-enabled", "web-server"] | no |
| metadata_startup_script | Startup script | string | "" | no |
| additional_metadata | Extra metadata | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| instance_name | VM name |
| instance_id | VM ID |
| static_ip | External IP (if enabled) |
| internal_ip | Internal IP |
| zone | VM zone |
| service_account_email | Service account email |
| ssh_command | SSH command to connect |
| instance_self_link | VM instance self-link |