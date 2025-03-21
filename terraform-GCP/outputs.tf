output "cluster_name" {
  value = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  value = google_container_cluster.primary.endpoint
}

output "client_certificate" {
  value     = google_container_cluster.primary.master_auth[0].client_certificate
  sensitive = true
}

output "client_key" {
  value     = google_container_cluster.primary.master_auth[0].client_key
  sensitive = true
}

output "cluster_ca_certificate" {
  value     = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive = true
}

output "application_external_ip" {
  value = (
    length(kubernetes_service.app_service.status[0].load_balancer[0].ingress) > 0 
    ? kubernetes_service.app_service.status[0].load_balancer[0].ingress[0].ip 
    : "No IP available"
  )
}
