# BackendConfig for health checks and backend settings
resource "kubernetes_manifest" "backend_config" {
  manifest = {
    apiVersion = "cloud.google.com/v1"
    kind       = "BackendConfig"
    metadata = {
      name      = "nginx-backend-config"
      namespace = kubernetes_namespace.care_namespace.metadata[0].name
    }
    spec = {
      timeoutSec = 60
      connectionDraining = {
        drainingTimeoutSec = 60
      }
      healthCheck = {
        checkIntervalSec = 30
        port             = 9000
        type             = "HTTP"
        requestPath      = "/health/"
      }
    }
  }
}

# Django Application Deployment
module "care_django_deployment" {
  source = "git::https://github.com/tellmeY18/terraform-kubernetes-deployment.git?ref=main"

  name      = "care-django-production"
  namespace = kubernetes_namespace.care_namespace.metadata[0].name
  image     = "ghcr.io/ohcnetwork/care:latest"
  command   = ["/app/start.sh"]
  replicas  = 2

  internal_port = [{
    name          = "django"
    internal_port = 9000
    host_port     = null
  }]

  env_from = [
    {
      config_map_ref = { name = "care-production" }
    },
    {
      secret_ref = { name = "care-production" }
    }
  ]
}

# Celery Beat Deployment
module "care_celery_beat" {
  source = "git::https://github.com/tellmeY18/terraform-kubernetes-deployment.git?ref=main"

  name      = "care-celery-beat"
  namespace = kubernetes_namespace.care_namespace.metadata[0].name
  image     = "ghcr.io/ohcnetwork/care:latest"
  command   = ["/app/celery_beat.sh"]
  replicas  = 1

  env_from = [
    {
      config_map_ref = { name = "care-production" }
    },
    {
      secret_ref = { name = "care-production" }
    }
  ]
}

# Celery Worker Deployment
module "care_celery_worker" {
  source = "git::https://github.com/tellmeY18/terraform-kubernetes-deployment.git?ref=main"

  name      = "care-celery-worker"
  namespace = kubernetes_namespace.care_namespace.metadata[0].name
  image     = "ghcr.io/ohcnetwork/care:latest"
  command   = ["/app/celery_worker.sh"]
  replicas  = 1

  env_from = [
    {
      config_map_ref = { name = "care-production" }
    },
    {
      secret_ref = { name = "care-production" }
    }
  ]
}

# Service with BackendConfig Integration
module "care_service" {
  source        = "terraform-iaac/service/kubernetes"
  app_name      = module.care_django_deployment.name
  app_namespace = kubernetes_namespace.care_namespace.metadata[0].name
  type          = "NodePort"

  port_mapping = [{
    name          = "http"
    internal_port = 9000
    external_port = 80
  }]

  annotations = {
    "cloud.google.com/neg"            = jsonencode({ ingress = true })
    "cloud.google.com/backend-config" = jsonencode({ default = "nginx-backend-config" })
  }

  depends_on = [
    kubernetes_manifest.backend_config,
    module.gke_cluster
  ]
}

resource "google_compute_ssl_policy" "care_ssl_policy" {
  name            = "care-ssl-policy"
  min_tls_version = "TLS_1_2"
  profile         = "MODERN" # Disables TLS 1.0/1.1 and weak ciphers
}

# Frontend Configuration
resource "kubernetes_manifest" "frontend_config" {
  manifest = {
    apiVersion = "networking.gke.io/v1beta1"
    kind       = "FrontendConfig"
    metadata = {
      name      = "nginx-frontend-config"
      namespace = kubernetes_namespace.care_namespace.metadata[0].name
    }
    spec = {
      redirectToHttps = { enabled = true }
    }
  }
}

# Managed SSL Certificate
resource "kubernetes_manifest" "managed_cert" {
  manifest = {
    apiVersion = "networking.gke.io/v1beta1"
    kind       = "ManagedCertificate"
    metadata = {
      name      = "nginx-cert"
      namespace = kubernetes_namespace.care_namespace.metadata[0].name
    }
    spec = {
      domains = [var.domain_name]
    }
  }
}

# Ingress Configuration
resource "kubernetes_ingress_v1" "nginx_ingress" {
  metadata {
    name      = "nginx-ingress"
    namespace = kubernetes_namespace.care_namespace.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                 = "gce"
      "kubernetes.io/ingress.global-static-ip-name" = google_compute_global_address.care_pip.name
      "networking.gke.io/managed-certificates"      = kubernetes_manifest.managed_cert.manifest.metadata.name
      "networking.gke.io/v1beta1.FrontendConfig"    = kubernetes_manifest.frontend_config.manifest.metadata.name
      "kubernetes.io/ingress.allow-http"            = "false"
    }
  }

  spec {
    rule {
      host = var.domain_name
      http {
        path {
          path      = "/*"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = module.care_service.name
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
    module.care_service,
    kubernetes_manifest.frontend_config,
  ]
}
