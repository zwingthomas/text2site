# Log Analytics Workspace (Optional)
resource "azurerm_log_analytics_workspace" "log_analytics" {
  name                = "${var.resource_group_name}-logs"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  sku                 = "PerGB2018"

  retention_in_days = 30
}

# Azure Key Vault
resource "azurerm_key_vault" "key_vault" {
  name                        = var.key_vault_name
  location                    = var.location
  resource_group_name         = var.key_vault_resource_group
  tenant_id                   = var.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = true
  enable_rbac_authorization   = true
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }
}

# Store Twilio Auth Token in Key Vault
resource "azurerm_key_vault_secret" "twilio_auth_token" {
  name         = "twilio-auth-token"
  value        = var.twilio_auth_token
  key_vault_id = azurerm_key_vault.key_vault.id
  depends_on   = [azurerm_role_assignment.aks_key_vault_access]
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
    outbound_type      = "userDefinedRouting"
  }

  api_server_access_profile {
    authorized_ip_ranges = var.trusted_ip_ranges
  }


  tags = {
    Environment = "Production"
  }
}

# Grant AKS access to Key Vault
resource "azurerm_role_assignment" "aks_key_vault_access" {
  scope                = azurerm_key_vault.key_vault.id
  role_definition_name = "Key Vault Reader"
  principal_id         = azurerm_kubernetes_cluster.aks_cluster.kubelet_identity[0].object_id
}
