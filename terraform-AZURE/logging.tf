# logging.tf

resource "azurerm_monitor_diagnostic_setting" "aks_diagnostic_kube_apiserver" {
  name               = "aks-diagnostic-kube-apiserver"
  target_resource_id = azurerm_kubernetes_cluster.example.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id

  enabled_log {
    category = "kube-apiserver"
  }
}

resource "azurerm_monitor_diagnostic_setting" "aks_diagnostic_kube_controller_manager" {
  name               = "aks-diagnostic-kube-controller-manager"
  target_resource_id = azurerm_kubernetes_cluster.example.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id

  enabled_log {
    category = "kube-controller-manager"
  }
}

resource "azurerm_monitor_diagnostic_setting" "aks_diagnostic_kube_scheduler" {
  name               = "aks-diagnostic-kube-scheduler"
  target_resource_id = azurerm_kubernetes_cluster.example.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id

  enabled_log {
    category = "kube-scheduler"
  }
}

resource "azurerm_monitor_diagnostic_setting" "aks_diagnostic_kube_audit" {
  name               = "aks-diagnostic-kube-audit"
  target_resource_id = azurerm_kubernetes_cluster.example.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id

  enabled_log {
    category = "kube-audit"
  }
}
