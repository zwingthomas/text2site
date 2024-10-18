# Kubernetes Secret for Twilio Auth Token
resource "kubernetes_secret" "twilio_auth_token" {
  metadata {
    name = "twilio-auth-token"
  }

  data = {
    twilio_auth_token = base64encode(var.twilio_auth_token)
  }
}

# Kubernetes Deployment
resource "kubernetes_deployment" "app_deployment" {
  metadata {
    name = "hello-world-app"
    labels = {
      app = "hello-world-app"
    }
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "hello-world-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "hello-world-app"
        }
      }

      spec {
        container {
          name  = "app"
          image = var.docker_image

          port {
            container_port = var.application_port
          }

          env {
            name = "twilio_auth_token"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.twilio_auth_token.metadata[0].name
                key  = "twilio_auth_token"
              }
            }
          }
        }
      }
    }
  }
}

# Kubernetes Service
resource "kubernetes_service" "app_service" {
  metadata {
    name = "hello-world-app-service"
  }

  spec {
    selector = {
      app = kubernetes_deployment.app_deployment.metadata[0].labels.app
    }

    port {
      protocol    = "TCP"
      port        = var.application_port
      target_port = var.application_port
    }

    type = "LoadBalancer"
  }
}

# Network Policy to Deny All Traffic by Default
resource "kubernetes_network_policy" "default_deny_all" {
  metadata {
    name      = "default-deny-all"
    namespace = "default"
  }

  spec {
    pod_selector {}

    policy_types = ["Ingress", "Egress"]
  }
}

# Network Policy to Allow Ingress to the Application
resource "kubernetes_network_policy" "allow_app_ingress" {
  metadata {
    name      = "allow-app-ingress"
    namespace = "default"
  }

  spec {
    pod_selector {
      match_labels = {
        app = "hello-world-app"
      }
    }

    ingress {
      from {
        ip_block {
          cidr = "0.0.0.0/0"  # Adjust as needed
        }
      }

      ports {
        port     = var.application_port
        protocol = "TCP"
      }
    }

    policy_types = ["Ingress"]
  }
}

# Horizontal Pod Autoscaler
resource "kubernetes_horizontal_pod_autoscaler" "app_hpa" {
  metadata {
    name = "hello-world-app-hpa"
  }

  spec {
    max_replicas = 5
    min_replicas = 3

    scale_target_ref {
      kind = "Deployment"
      name = kubernetes_deployment.app_deployment.metadata[0].name
      api_version = "apps/v1"
    }

    target_cpu_utilization_percentage = 60
  }
}
