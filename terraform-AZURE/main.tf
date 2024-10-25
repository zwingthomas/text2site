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

# Grant AKS access to Key Vault
resource "azurerm_role_assignment" "aks_key_vault_access" {
  scope                = azurerm_key_vault.key_vault.id
  role_definition_name = "Key Vault Reader"
  principal_id         = azurerm_kubernetes_cluster.aks_cluster.kubelet_identity[0].object_id
}
