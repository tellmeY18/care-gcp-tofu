module "nginx_deployment" {
  source       = "terraform-iaac/deployment/kubernetes"
  name         = "nginx"
  namespace    = "default"
  image        = "nginx:latest"
  replicas     = 1
  internal_port = [{
    name          = "http"
    internal_port = 80
    host_port     = null
  }]
}

module "nginx_service" {
  source        = "terraform-iaac/service/kubernetes"
  app_name      = module.nginx_deployment.name
  app_namespace = module.nginx_deployment.namespace
  type          = "NodePort"

  port_mapping = [{
    name          = "http"
    internal_port = 80
    external_port = 80
  }]

  annotations = {
    # Enable container-native load balancing (NEG)
    "cloud.google.com/neg" = jsonencode({ ingress = true })
    # Attach GCP BackendConfig
    "cloud.google.com/backend-config" = jsonencode({ default = "nginx-backend-config" })
  }
}

resource "kubernetes_manifest" "backend_config" {
  manifest = {
    apiVersion = "cloud.google.com/v1"
    kind       = "BackendConfig"
    metadata = {
      name      = "nginx-backend-config"
      namespace = module.nginx_service.namespace
    }
    spec = {
      healthCheck = {
        checkIntervalSec    = 15
        timeoutSec          = 5
        healthyThreshold    = 1
        unhealthyThreshold  = 2
        type                = "HTTP"
        requestPath         = "/"
        port                = 80
      }
    }
  }
}

resource "kubernetes_manifest" "frontend_config" {
  manifest = {
    apiVersion = "networking.gke.io/v1beta1"
    kind       = "FrontendConfig"
    metadata = {
      name      = "nginx-frontend-config"
      namespace = module.nginx_service.namespace
    }
    spec = {
      redirectToHttps = { enabled = true }
    }
  }
}

resource "kubernetes_annotations" "service_annotations" {
  api_version = "v1"
  kind        = "Service"
  metadata {
    name      = module.nginx_service.name
    namespace = module.nginx_service.namespace
  }
  annotations = {
    "cloud.google.com/neg"            = jsonencode({ ingress = true })
    "cloud.google.com/backend-config" = jsonencode({ default = "nginx-backend-config" })
  }
  depends_on = [
    module.nginx_service,
    kubernetes_manifest.backend_config
  ]
}

resource "kubernetes_manifest" "managed_cert" {
  manifest = {
    apiVersion = "networking.gke.io/v1beta1"
    kind       = "ManagedCertificate"
    metadata = {
      name      = "nginx-cert"
      namespace = module.nginx_service.namespace
    }
    spec = {
      domains = [var.domain_name]
    }
  }
}

resource "kubernetes_ingress_v1" "nginx_ingress" {
  metadata {
    name      = "nginx-ingress"
    namespace = module.nginx_service.namespace
    annotations = {
      "kubernetes.io/ingress.class"                 = "gce"
      "kubernetes.io/ingress.global-static-ip-name" = google_compute_global_address.nginx_static_ip.name
      "networking.gke.io/managed-certificates"      = kubernetes_manifest.managed_cert.manifest.metadata.name
      "kubernetes.io/ingress.allow-http"            = "false"
    }
  }

  spec {
    rule {
      host = var.domain_name
      http {
        path {
          path      = "/"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = module.nginx_service.name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_manifest.managed_cert,              
    module.nginx_service,
    kubernetes_manifest.frontend_config,
    kubernetes_annotations.service_annotations
  ]
}

resource "google_compute_global_address" "nginx_static_ip" {
  name = "nginx-static-ip"
}

output "load_balancer_ip" {
  description = "Global static IP of the Ingress"
  value       = google_compute_global_address.nginx_static_ip.address
}

output "ingress_status" {
  description = "Status of the GKE Ingress"
  value       = kubernetes_ingress_v1.nginx_ingress.status
}

output "domain" {
  description = "Configured domain for nginx"
  value       = var.domain_name
}

