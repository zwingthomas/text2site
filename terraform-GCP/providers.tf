terraform {
  required_version = ">= 0.13"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "= 6.7.0"
    }
  }
  
  backend "gcs" {
    bucket  = "tfstate-zwinger"
    prefix  = "terraform/state"
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = file(var.credentials_file)
}

# Use a null_resource that depends on the cluster
resource "null_resource" "wait_for_cluster" {
  depends_on = [google_container_cluster.primary]

  provisioner "local-exec" {
    command = "echo GKE Cluster is ready"
  }
}

# Kubernetes provider using the GKE cluster data
provider "kubernetes" {
  host                   = google_container_cluster.primary.endpoint
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
  token                  = data.google_client_config.default.access_token
}

# Ensure that the kubernetes provider is only configured after the GKE cluster
data "google_client_config" "default" {}