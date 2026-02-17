# Firewall Rules Module

Creates standard firewall rules for a VPC network.

## Usage

### Basic (Allow SSH from anywhere, HTTP/HTTPS)
```hcl
module "firewall" {
  source = "../../modules/firewall-rules"
  
  project_id   = "my-project-123456"
  network_id   = module.vpc.network_id
  company_name = "company-a"
  environment  = "prod"
}
```

### Production (Restrict SSH to office IPs)
```hcl
module "firewall" {
  source = "../../modules/firewall-rules"
  
  project_id   = "my-project-123456"
  network_id   = module.vpc.network_id
  company_name = "company-a"
  environment  = "prod"
  
  allow_ssh_from_anywhere = false
  allowed_ssh_ranges      = [
    "203.0.113.0/24",    # Office IP range
    "198.51.100.0/24"    # VPN IP range
  ]
}
```

### With Custom Ports
```hcl
module "firewall" {
  source = "../../modules/firewall-rules"
  
  project_id   = "my-project-123456"
  network_id   = module.vpc.network_id
  company_name = "company-a"
  environment  = "prod"
  
  custom_ports = [
    {
      protocol = "tcp"
      ports    = ["8080", "8443"]  # Application ports
    }
  ]
}
```

## Firewall Rules Created

| Rule | Source | Target | Ports | Tag |
|------|--------|--------|-------|-----|
| SSH | Configurable | All with tag | 22 | ssh-enabled |
| HTTP/HTTPS | 0.0.0.0/0 | All with tag | 80, 443 | web-server |
| Internal | 10.0.0.0/8 | All | All | - |
| ICMP | 0.0.0.0/0 | All | ICMP | - |

## Network Tags

Apply these tags to VMs to enable firewall rules:
```hcl
resource "google_compute_instance" "vm" {
  # ...
  tags = ["ssh-enabled", "web-server"]
}
```

## Security Best Practices

**Production environments:**
- Set `allow_ssh_from_anywhere = false`
- Specify `allowed_ssh_ranges` with your office/VPN IPs
- Consider using Identity-Aware Proxy (IAP) instead of direct SSH

**Development environments:**
- `allow_ssh_from_anywhere = true` is acceptable for ease of use

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_id | GCP Project ID | string | - | yes |
| network_id | VPC network ID | string | - | yes |
| company_name | Company name | string | - | yes |
| environment | Environment | string | - | yes |
| allow_ssh_from_anywhere | Allow SSH from 0.0.0.0/0 | bool | true | no |
| allowed_ssh_ranges | SSH source IP ranges | list(string) | [] | no |
| allow_http_https | Enable HTTP/HTTPS rules | bool | true | no |
| internal_ranges | Internal IP ranges | list(string) | ["10.0.0.0/8"] | no |
| custom_ports | Custom port rules | list(object) | [] | no |

## Outputs

| Name | Description |
|------|-------------|
| ssh_firewall_name | SSH firewall rule name |
| web_firewall_name | HTTP/HTTPS firewall rule name |
| internal_firewall_name | Internal traffic rule name |