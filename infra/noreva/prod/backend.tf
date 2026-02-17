terraform {
  backend "gcs" {
    bucket = "noreva-prod-terraform-state"
    prefix = "noreva/prod"
  }
}