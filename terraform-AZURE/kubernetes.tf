provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks_cluster.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config[0].cluster_ca_certificate)
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = var.aks_cluster_name
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  dns_prefix          = "${var.aks_cluster_name}-dns"

  kubernetes_version = var.aks_version

  default_node_pool {
    name           = "default"
    vm_size        = var.node_vm_size
    node_count     = var.node_count
    vnet_subnet_id = azurerm_subnet.aks_subnet.id
    temporary_name_for_rotation = "helloWorldAppTemp"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = "azure"
    network_policy     = "azure"
    dns_service_ip     = "10.2.0.10"
    service_cidr       = "10.2.0.0/24"
    # docker_bridge_cidr = "172.17.0.1/16"
    outbound_type      = "loadBalancer"
  }

  

  api_server_access_profile {
    authorized_ip_ranges = var.trusted_ip_ranges
  }


  tags = {
    Environment = "Production"
  }
}

# Create Kubernetes Secret using Key Vault
data "azurerm_key_vault_secret" "twilio_auth_token" {
  name         = azurerm_key_vault_secret.twilio_auth_token.name
  key_vault_id = azurerm_key_vault.key_vault.id
}

resource "kubernetes_secret" "twilio_auth_token" {
  metadata {
    name = "twilio-auth-token"
  }

  data = {
    twilio_auth_token = base64encode(data.azurerm_key_vault_secret.twilio_auth_token.value)
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
    replicas = 1

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
    max_replicas = 1
    min_replicas = 1

    scale_target_ref {
      kind       = "Deployment"
      name       = kubernetes_deployment.app_deployment.metadata[0].name
      api_version = "apps/v1"
    }

    target_cpu_utilization_percentage = 60
  }
}

# Reference an existing ACR
data "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = "helloWorldApp"
}

# Assign AcrPull role to AKS managed identity
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks_cluster.identity[0].principal_id
}

# Assign AcrPull role to AKS Kubelet managed identity
resource "azurerm_role_assignment" "aks_kubelet_acr_pull" {
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks_cluster.kubelet_identity[0].object_id
}