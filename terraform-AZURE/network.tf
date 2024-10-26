# Resource Group
resource "azurerm_resource_group" "aks_rg" {
  name     = var.resource_group_name
  location = var.location
}

# Virtual Network for AKS
resource "azurerm_virtual_network" "vnet" {
  name                = "aks-vnet"
  address_space       = ["10.0.0.0/8"]
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
}

# Subnet for AKS with Service Endpoints
resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.aks_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.0.0/16"]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.AzureActiveDirectory"]
}

# Route Table for AKS
resource "azurerm_route_table" "aks_route_table" {
  name                = "aks-route-table"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
}

# Default route for outbound traffic from AKS
resource "azurerm_route" "default_route" {
  name                   = "default-route"
  resource_group_name     = azurerm_resource_group.aks_rg.name
  route_table_name        = azurerm_route_table.aks_route_table.name
  address_prefix          = "0.0.0.0/0"
  next_hop_type           = "Internet"
}

# Associate Route Table with Subnet
resource "azurerm_subnet_route_table_association" "aks_subnet_route_table" {
  subnet_id      = azurerm_subnet.aks_subnet.id
  route_table_id = azurerm_route_table.aks_route_table.id
}

# Network Security Group (NSG)
resource "azurerm_network_security_group" "aks_nsg" {
  name                = "aks-nsg"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
}

# nsg was too restrictive. Check error and limit later
resource "azurerm_network_security_rule" "allow_all_outbound" {
  name                        = "AllowAllOutbound"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.aks_nsg.name
  resource_group_name         = azurerm_resource_group.aks_rg.name
}


# Associate NSG with Subnet
resource "azurerm_subnet_network_security_group_association" "aks_subnet_nsg" {
  subnet_id                 = azurerm_subnet.aks_subnet.id
  network_security_group_id = azurerm_network_security_group.aks_nsg.id
}

# Allow outbound egress for necessary ports (443, 53, etc.)
# resource "azurerm_network_security_rule" "allow_egress" {
#   name                        = "AllowEgress"
#   priority                    = 100
#   direction                   = "Outbound"
#   access                      = "Allow"
#   protocol                    = "Tcp"
#   source_port_range           = "*"
#   destination_port_ranges     = ["443", "53", "80", "9000", "1194"]  # Allow HTTPS, using custom DNS servers, ensure they're accessible by the cluster nodes, DNS, HTTP, for tunneled secure communication between the nodes and the control plane.
#   source_address_prefix       = "*"
#   destination_address_prefix  = "0.0.0.0/0"
#   network_security_group_name = azurerm_network_security_group.aks_nsg.name
#   resource_group_name         = azurerm_resource_group.aks_rg.name
# }

# Allow inbound Kubernetes API traffic from trusted IP ranges
resource "azurerm_network_security_rule" "allow_k8s_api" {
  name                        = "AllowK8sAPI"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  source_address_prefixes     = var.trusted_ip_ranges
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.aks_nsg.name
  resource_group_name         = azurerm_resource_group.aks_rg.name
}

# Cloud NAT configuration to ensure AKS outbound internet access
resource "azurerm_nat_gateway" "aks_nat_gateway" {
  name                = "aks-nat-gateway"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  sku_name            = "Standard"
}

# Associate NAT Gateway with the Subnet for outbound traffic
resource "azurerm_subnet_nat_gateway_association" "aks_subnet_nat_gateway" {
  subnet_id      = azurerm_subnet.aks_subnet.id
  nat_gateway_id = azurerm_nat_gateway.aks_nat_gateway.id
}
