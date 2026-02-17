
# VPC Network Module

Creates a VPC network with a subnet and Cloud Router for a given environment.

## Usage
```hcl
module "vpc" {
  source = "../../modules/vpc-network"
  
  project_id   = "my-project-123456"
  region       = "us-east4"
  company_name = "company-a"
  environment  = "prod"
  cidr_range   = "10.1.0.0/24"
  
  enable_private_google_access = true
  enable_flow_logs             = false
}
```

## Features

- Custom VPC network (not auto-created subnets)
- Single subnet per environment
- Private Google Access (optional)
- VPC Flow Logs (optional)
- Cloud Router (for future Cloud NAT setup)
- Configurable routing mode

## CIDR Allocation

Plan your CIDR ranges to avoid conflicts:
```
karbone-prod:    10.1.0.0/24
karbone-dev:     10.2.0.0/24
noreva-prod:    10.3.0.0/24
noreva-dev:     10.4.0.0/24
common-services-prod: 10.10.0.0/24
common-services-dev:  10.11.0.0/24
```

## Adding Cloud NAT

To add Cloud NAT for VMs without external IPs:
```hcl
resource "google_compute_router_nat" "nat" {
  name   = "${var.company_name}-${var.environment}-nat"
  router = module.vpc.router_name
  region = var.region

  nat_ip_allocate_option = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_id | GCP Project ID | string | - | yes |
| region | GCP region | string | - | yes |
| company_name | Company/tenant name | string | - | yes |
| environment | Environment (prod/dev/staging/test) | string | - | yes |
| cidr_range | Subnet CIDR range | string | - | yes |
| enable_private_google_access | Enable Private Google Access | bool | true | no |
| enable_flow_logs | Enable VPC Flow Logs | bool | false | no |
| routing_mode | REGIONAL or GLOBAL | string | "REGIONAL" | no |

## Outputs

| Name | Description |
|------|-------------|
| network_id | VPC network ID |
| network_name | VPC network name |
| network_self_link | VPC network self-link |
| subnetwork_id | Subnet ID |
| subnetwork_name | Subnet name |
| subnetwork_self_link | Subnet self-link |
| subnetwork_cidr | Subnet CIDR range |
| router_name | Cloud Router name |
| router_id | Cloud Router ID |

