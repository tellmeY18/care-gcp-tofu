#module "kms" {
#  source          = "terraform-google-modules/kms/google"
#  version         = "~> 4.0"
#  project_id      = var.project_id
#  keyring         = "ohn-debug-${var.environment}-keyring"
#  location        = "asia-south1"
#  keys            = ["vpc-flow-logs-key", "database-key", "patient-key", "facility-key"]
#  prevent_destroy = false 
#  depends_on = [
#    module.project_services
#  ]
#}
