module "gke_cluster" {
  source  = "terraform-google-modules/kubernetes-engine/google"
  version = "~> 36.3"

  project_id               = var.project_id
  name                     = var.cluster_name
  regional                 = false
  region                   = var.region
  zones                    = [var.zone]
  network                  = module.vpc.network_name
  subnetwork               = module.vpc.subnets_names[1]
  deletion_protection      = false
  ip_range_pods            = google_compute_global_address.pods_range.name
  ip_range_services        = google_compute_global_address.services_range.name
  remove_default_node_pool = true

  node_pools = [
    for np in var.node_pools : {
      name         = np.name
      machine_type = np.machine_type
      min_count    = np.min_count
      max_count    = np.max_count
      preemptible  = np.preemptible
      disk_size_gb = np.disk_size_gb
    }
  ]
}

output "gke_cluster_name" {
  description = "The name of the GKE cluster"
  value       = module.gke_cluster.name
}

output "gke_endpoint" {
  description = "The endpoint of the GKE cluster"
  value       = module.gke_cluster.endpoint
}

output "gke_ca_certificate" {
  description = "The base64 encoded public certificate for the cluster"
  value       = module.gke_cluster.ca_certificate
  sensitive   = true
}
