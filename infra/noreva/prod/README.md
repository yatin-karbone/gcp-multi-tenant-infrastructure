# Company A Production Infrastructure

Terraform configuration for Noreva's production environment running a containerized Django application.

## Architecture
```
┌─────────────────────────────────────────────────┐
│ Internet                                        │
└────────────────┬────────────────────────────────┘
                 │
                 │ HTTPS (443)
                 │ HTTP (80)
                 │
         ┌───────▼────────┐
         │   Static IP    │
         │  (DNS A Record)│
         └───────┬────────┘
                 │
    ┌────────────▼────────────┐
    │   GCP Firewall Rules    │
    │  - Allow 80, 443, 22    │
    └────────────┬────────────┘
                 │
       ┌─────────▼──────────┐
       │   Ubuntu 24.04 VM  │
       │   2 vCPU, 8GB RAM  │
       │   100GB Disk       │
       │                    │
       │  ┌──────────────┐  │
       │  │   Docker     │  │
       │  │              │  │
       │  │  - Nginx     │  │
       │  │  - Django    │  │
       │  │  - PostgreSQL│  │
       │  │  - Redis     │  │
       │  │  - Celery    │  │
       │  │  - imgproxy  │  │
       │  │  - Portainer │  │
       │  └──────────────┘  │
       └────────────────────┘
                 │
                 │ 
       ┌─────────▼──────────┐
       │   Cloud Storage    │
       │  - Uploads Backup  │
       │  - DB Backups      │
       └────────────────────┘
```

## Quick Start

1. Update `terraform.tfvars` with your project ID and domain
2. Create Terraform state bucket
3. Run `terraform init`
4. Run `terraform apply`
5. SSH to VM and install Docker manually using `scripts/startup.sh`

## VM Specs

- OS: Ubuntu 24.04 LTS
- vCPU: 2
- RAM: 8 GB
- Disk: 100 GB (pd-balanced)

## What Gets Created

- VPC network with subnet
- Firewall rules (SSH, HTTP, HTTPS)
- VM with static IP
- IAM permissions for infra-admins and external-developers
- GCS buckets for backups (optional)

## Manual Docker Installation

After VM is created, SSH and run:
```bash
gcloud compute scp scripts/startup.sh company-a-prod-app-vm:/tmp/ --zone=us-central1-a
gcloud compute ssh company-a-prod-app-vm --zone=us-central1-a
sudo bash /tmp/startup.sh
```