# GCP Multi-Tenant Infrastructure

This repository contains the Terraform Infrastructure-as-Code (IaC) for deploying and managing Google Cloud resources for Karbone's multi-tenant environments.

## 🏗 Project Structure

.
├── infra/
│   ├── modules/                  # Reusable Terraform modules
│   │   ├── app-vm/               # Compute Engine VM + IAM + Static IP
│   │   ├── firewall-rules/       # Standard firewall policies
│   │   ├── project-iam/          # Project-level IAM bindings
│   │   └── vpc-network/          # Custom VPC & Subnets
│   │
│   └── noreva/                   # Tenant: Noreva
│       └── prod/                 # Environment: Production
│           ├── main.tf           # Main resource definitions
│           ├── variables.tf      # Variable declarations
│           ├── outputs.tf        # Output values (IPs, SSH commands)
│           ├── backend.tf        # Remote state configuration (GCS)
│           └── terraform.tfvars  # Configuration values (NOT committed)


🚀 Getting Started
Prerequisites
1. Google Cloud SDK: Install gcloud CLI
2. Terraform: Install Terraform
3. Authentication: 
    gcloud auth application-default login


Deployment (Example: Noreva Production)
1. Navigate to the environment directory:
    cd infra/noreva/prod
2. Initialize Terraform:
    terraform init
3. Review the Plan:
    terraform plan
4. Apply Changes:
    terraform apply

🔐 Access & Security
SSH Access (IAP Tunnel)
We do not use public SSH keys or Bastion hosts. Access is managed via Identity-Aware Proxy (IAP) and OS Login.
To connect to a VM:
    gcloud compute ssh <vm-name> --project=<project-id> --zone=<zone> --tunnel-through-iap

Example for Noreva Prod:
    gcloud compute ssh noreva-prod-vm --project=noreva-prod-apps-67ca --zone=us-east4-a --tunnel-through-iap

External Developers
External contractors must be added to the appropriate Google Group (e.g., nor-prod-prodapps-norhub-ext@karbone.com) to gain access. They must authenticate using a Google Account (Workspace or Gmail).

🛠 Modules Overview
vpc-network	-> Creates a custom VPC and subnet with Private Google Access enabled.
firewall-rules -> standardizes ingress rules (SSH via IAP, HTTP/HTTPS, Internal traffic).
app-vm -> Deploys a hardened Compute Engine instance with a Static IP and Service Account.
project-iam -> Manages project-level IAM bindings for Admin and Developer groups.

📦 State Management
Terraform state is stored remotely in Google Cloud Storage (GCS) buckets to enable collaboration and state locking.
Bucket Format: noreva-prod-terraform-state
Location: us-east4