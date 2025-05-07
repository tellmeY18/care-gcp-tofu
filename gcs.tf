module "service_accounts" {
  source       = "terraform-google-modules/service-accounts/google"
  version      = "~> 4.5.3"
  project_id   = var.project_id
  names        = ["ohn-${var.environment}-${var.app}-writer"]
  display_name = "Bucket Writer Service Account"
  descriptions = ["Service Account for writing to buckets"]
}

resource "google_kms_crypto_key_iam_member" "writer_sa_patient" {
  crypto_key_id = "projects/${var.project_id}/locations/global/keyRings/ohn-${var.environment}-keyring/cryptoKeys/patient-key"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${local.writer_sa_email}"
}

resource "google_kms_crypto_key_iam_member" "writer_sa_facility" {
  crypto_key_id = "projects/${var.project_id}/locations/global/keyRings/ohn-${var.environment}-keyring/cryptoKeys/facility-key"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${local.writer_sa_email}"
}

resource "google_kms_crypto_key_iam_member" "writer_sa_vpc_flow_logs" {
  crypto_key_id = "projects/${var.project_id}/locations/global/keyRings/ohn-${var.environment}-keyring/cryptoKeys/vpc-flow-logs-key"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${local.writer_sa_email}"
}

module "patient_bucket" {
  source     = "terraform-google-modules/cloud-storage/google"
  version    = "~> 10.0"
  project_id = var.project_id
  location   = var.region
  names      = [local.patient_bucket_name]
  bucket_policy_only = {
    "${local.patient_bucket_name}" = true
  }
  cors = [
    {
      origin          = ["https://${var.cdn_domain_name}"]
      method          = ["GET", "PUT", "POST"]
      response_header = ["*"]
      max_age_seconds = 3000
    }
  ]

  depends_on = [module.service_accounts]
}

module "facility_bucket" {
  source     = "terraform-google-modules/cloud-storage/google"
  version    = "~> 10.0"
  project_id = var.project_id
  location   = var.region
  names      = [local.facility_bucket_name]
  bucket_policy_only = {
    "${local.facility_bucket_name}" = true
  }
  cors = [
    {
      origin          = ["https://${var.cdn_domain_name}"]
      method          = ["GET", "PUT", "POST"]
      response_header = ["*"]
      max_age_seconds = 3000
    }
  ]

  depends_on = [module.service_accounts]
}

resource "google_storage_bucket_iam_member" "patient_bucket_admin" {
  bucket = module.patient_bucket.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${local.writer_sa_email}"

  depends_on = [module.patient_bucket]
}

resource "google_storage_bucket_iam_member" "facility_bucket_admin" {
  bucket = module.facility_bucket.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${local.writer_sa_email}"

  depends_on = [module.facility_bucket]
}

resource "google_storage_bucket_iam_member" "public_facility" {
  bucket = module.facility_bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"

  depends_on = [module.facility_bucket]
}

output "writer_service_account_email" {
  description = "The email of the service account used for bucket operations"
  value       = local.writer_sa_email
}

output "patient_bucket_name" {
  description = "The name of the patient bucket"
  value       = module.patient_bucket.name
}

output "facility_bucket_name" {
  description = "The name of the facility bucket"
  value       = module.facility_bucket.name
}
