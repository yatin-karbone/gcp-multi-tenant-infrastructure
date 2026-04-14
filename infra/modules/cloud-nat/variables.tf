variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "router_name" {
  type        = string
  description = "Name of the existing Cloud Router to attach to"
}

variable "nat_name" {
  type        = string
  description = "Name for the NAT gateway"
}

variable "static_ip_name" {
  type        = string
  description = "Name for the reserved static IP"
}

variable "subnet_self_links" {
  type        = list(string)
  description = "List of subnet self_links to route through this NAT"
}
