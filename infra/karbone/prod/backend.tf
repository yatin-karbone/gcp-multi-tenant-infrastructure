terraform {
  backend "gcs" {
    bucket = "karbone-tf-state-prod"
    prefix = "terraform/state/karbone-app"
  }
}
