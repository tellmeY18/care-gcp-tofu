locals {
  required_tags = {
    terraform   = "true"
    environment = var.environment
    project     = "care"
  }
  #  alloydb_sa = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-alloydb.iam.gserviceaccount.com"
  tags                 = local.required_tags
  image                = "ghcr.io/ohcnetwork/care:latest-475"
  database_subnets     = "10.0.21.0/24"
  gke_subnets          = var.gke_subnets
  gke_pods_range       = var.gke_pods_range
  gke_services_range   = var.gke_services_range
  writer_sa_email      = module.service_accounts.email
  patient_bucket_name  = "ohn-${var.environment}-${var.app}-patient"
  facility_bucket_name = "ohn-${var.environment}-${var.app}-facility"
}
