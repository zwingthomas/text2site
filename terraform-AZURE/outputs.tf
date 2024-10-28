output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.aks_cluster.name
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks_cluster.kube_config_raw
  sensitive = true
}

output "application_fqdn" {
  value = azurerm_kubernetes_cluster.aks_cluster.fqdn
}

output "load_balancer_ip" {
  value = data.kubernetes_service.app_service_status.status[0].load_balancer[0].ingress[0].ip
  description = "The external IP of the Kubernetes LoadBalancer service."
}