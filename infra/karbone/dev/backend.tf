terraform {
  backend "gcs" {
    bucket = "karbone-tf-state-dev"
    prefix = "terraform/state/karbone-app"
  }
}
