terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.77.0"
    }
  }

  backend "gcs" {
    bucket = "${var.project_id}-tfstate"
    prefix = "dev"
  }
}

data "google_project" "project" {
  project_id = var.project_id
}

data "google_client_config" "default" {}

provider "google" {
  region  = var.region
  project = var.project_id
}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

module "project_services" {
  source                      = "terraform-google-modules/project-factory/google//modules/project_services"
  project_id                  = var.project_id
  disable_services_on_destroy = false
  activate_apis = [
    "compute.googleapis.com",
    "iam.googleapis.com",
    "container.googleapis.com"
  ]
}

module "gke" {
  source            = "terraform-google-modules/kubernetes-engine/google"
  project_id        = var.project_id
  name              = "${var.deployment_name}-cluster"
  regional          = true
  region            = var.region
  zones             = [var.zone1, var.zone2, var.zone3]
  network           = "default"
  subnetwork        = "default"
  ip_range_pods     = ""
  ip_range_services = ""

  node_pools = [
    {
      name         = "${var.deployment_name}-node-pool"
      node_count   = 2
      machine_type = "e2-standard-4"
      min_count    = 1
      max_count    = 100
    }
  ]

  node_pools_oauth_scopes = {
    all = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  depends_on = [
    module.project_services
  ]
}
