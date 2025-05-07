module "nginx_deployment" {
  source    = "terraform-iaac/deployment/kubernetes"
  name      = "nginx"
  namespace = "default"
  image     = "nginx:latest"

  internal_port = [
    {
      name          = "http"
      internal_port = 80
      host_port     = 80
    }
  ]

  replicas = 1
}

module "nginx_service" {
  source        = "terraform-iaac/service/kubernetes"
  app_name      = module.nginx_deployment.name
  app_namespace = module.nginx_deployment.namespace

  port_mapping = [
    {
      name          = "http"
      internal_port = 80
      external_port = 80
    }
  ]

  type = "LoadBalancer"
}

data "kubernetes_service" "nginx" {
  metadata {
    name      = module.nginx_service.name
    namespace = module.nginx_service.namespace
  }

  depends_on = [module.nginx_service]
}

output "nginx_service_ip" {
  description = "External LoadBalancer IP for the NGINX service"
  value       = data.kubernetes_service.nginx.status[0].load_balancer[0].ingress[0].ip
}

