# logging.tf

resource "azurerm_monitor_diagnostic_setting" "aks_diagnostic" {
  name               = "aks-diagnostic-setting"
  target_resource_id = azurerm_kubernetes_cluster.aks_cluster.id

  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics.id

  enabled_log {
    category = ["kube-apiserver", "kube-controller-manager", "kube-scheduler", "kube-audit"]
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
