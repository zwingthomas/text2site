terraform {
  required_version = ">= 0.13"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "= 6.7.0"
    }
  }
}



provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = file(var.credentials_file)
}