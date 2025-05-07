#module "service_accounts" {
#  source        = "terraform-google-modules/service-accounts/google"
#  version       = "~> 4.5.3"
#  project_id    = var.project_id
#  # Create exactly one SA named "ohn-<env>-<app>-writer"
#  names         = ["ohn-${var.environment}-${var.app}-writer"]
#  # The module expects a single string, not a list
#  display_name  = "Bucket Writer Service Account"
#  descriptions  = ["Service Account for writing to buckets"]
#}
#
## Use a local for the service account name to ensure consistency
#locals {
#  writer_sa_name = "ohn-${var.environment}-${var.app}-writer"
#}
#
#module "bucket_writer_iam" {
#  source  = "terraform-google-modules/iam/google//modules/storage_buckets_iam"
#  version = "~> 8.1"
#  
#  storage_buckets = module.storage_buckets.bucket_names 
#  mode            = "additive"
#  
#  bindings = {
#    "roles/storage.admin" = [
#      "serviceAccount:${module.service_accounts.email}"
#    ]
#  }
#  
#  depends_on = [module.service_accounts]
#}
#
#output "writer_service_account_email" {
#  description = "The email of the service account used for bucket operations"
#  value       = module.service_accounts.email
#}
