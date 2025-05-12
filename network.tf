resource "google_compute_global_address" "care_pip" {
  name = "care-pip"
}

module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 11.0"

  project_id   = var.project_id
  network_name = "ohn-${var.environment}"

  subnets = [
    {
      subnet_name        = "database"
      subnet_ip          = local.database_subnets
      subnet_region      = var.region
      subnet_flow_logs   = true
      flow_logs_metadata = "INCLUDE_ALL_METADATA"
      flow_logs_sampling = 0.5
      flow_logs_interval = "INTERVAL_10_MIN"
    },
    {
      subnet_name        = "gke"
      subnet_ip          = var.gke_subnets
      subnet_region      = var.region
      subnet_flow_logs   = true
      flow_logs_metadata = "INCLUDE_ALL_METADATA"
      flow_logs_sampling = 0.5
      flow_logs_interval = "INTERVAL_10_MIN"
    }
  ]

  secondary_ranges = {
    gke = [
      {
        range_name    = "gke-pods-range"
        ip_cidr_range = var.gke_pods_range
      },
      {
        range_name    = "gke-services-range"
        ip_cidr_range = var.gke_services_range
      }
    ]
  }
  routes = []
}

# GKE Pod and Service IP ranges for VPC-native cluster
resource "google_compute_global_address" "pods_range" {
  name          = "gke-pods-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = module.vpc.network_self_link
}

resource "google_compute_global_address" "services_range" {
  name          = "gke-services-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 20
  network       = module.vpc.network_self_link
}



module "vpc_flow_logs_bucket" {
  source  = "terraform-google-modules/cloud-storage/google"
  version = "~> 10.0"

  project_id = var.project_id
  location   = "asia-south1"
  names      = ["ohn-${var.environment}-vpc-flow-logs"]

  # Enforce uniform bucket-level access (no ACLs)
  bucket_policy_only = {
    "ohn-${var.environment}-vpc-flow-logs" = true
  }
}

#### 3. Sink VPC Flow Logs into the GCS Bucket
module "vpc_flow_logs_export" {
  source  = "terraform-google-modules/log-export/google"
  version = "~> 10.0"

  parent_resource_id   = var.project_id
  parent_resource_type = "project"
  log_sink_name        = "vpc-flow-logs-sink-${var.environment}"

  # Only capture VPC subnet flow logs
  filter          = "resource.type=\"gce_subnetwork\" AND logName=\"projects/${var.project_id}/logs/compute.googleapis.com%2Fvpc_flows\""
  destination_uri = "storage.googleapis.com/${module.vpc_flow_logs_bucket.names["ohn-${var.environment}-vpc-flow-logs"]}"


  unique_writer_identity = true
}

#### 4. Outputs for Downstream Modules
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.network_id
}

output "database_subnets" {
  description = "List of database subnet self-links"
  value       = module.vpc.subnets_self_links
}

output "vpc_flow_logs_bucket_name" {
  description = "Name of the bucket receiving VPC flow logs"
  value       = keys(module.vpc_flow_logs_bucket.names)[0]
}

output "vpc_flow_logs_sink_identity" {
  description = "Service account identity used by the log sink"
  value       = module.vpc_flow_logs_export.writer_identity
}

