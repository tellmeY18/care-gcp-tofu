variable "project_id" {
}

variable "environment" {
}

variable "gke_subnets" {
  description = "Primary IP range for GKE subnet"
  type        = string
}

variable "gke_pods_range" {
  description = "Secondary IP range for GKE pods"
  type        = string
}

variable "gke_services_range" {
  description = "Secondary IP range for GKE services"
  type        = string
}

variable "region" {
}
variable "app" {

}

variable "domain_name" {
}

variable "alloydb_cpu_count" {
  description = "The number of CPUs to allocate for the AlloyDB machine."
  type        = number
}
variable "alloydb_read_pool_size" {
  type = number
}
variable "zones" {
  type = list(string)
}
variable "cdn_domain_name" {
  description = "The domain name for the CDN."
  type        = string
}
variable "cluster_name" {
  description = "The name of the GKE cluster."
  type        = string
}
variable "zone" {
  description = "The zone for the GKE cluster."
  type        = string
}
variable "node_pools" {
  description = "The node pools for the GKE cluster."
  type        = list(map(string))
}
