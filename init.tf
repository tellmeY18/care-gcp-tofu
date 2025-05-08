terraform {
  backend "gcs" {
    # configure bucket, prefix, credentials, etc.
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.33.0"
    }
     google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.33.0"
    }
   random = {
      source  = "hashicorp/random"
      version = "~> 3.7.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "google" {
  project = "k3s-test-452213"
  region  = "asia-south1"
}

provider "google-beta" {
  project = "k3s-test-452213"
  region  = "asia-south1"
}

data "google_container_cluster" "primary" {
  name     = module.gke_cluster.name
  location = var.zone
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
}
