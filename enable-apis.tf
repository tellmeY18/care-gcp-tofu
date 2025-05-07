module "project_services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 18.0"

  project_id = var.project_id

  activate_apis = [
    "compute.googleapis.com",
    "storage.googleapis.com",
    "alloydb.googleapis.com",
    "cloudkms.googleapis.com",
    "servicenetworking.googleapis.com",
    "serviceusage.googleapis.com",
    "iam.googleapis.com",
  ]

  enable_apis                 = true
  disable_services_on_destroy = false
}

