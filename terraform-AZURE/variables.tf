variable "subscription_id" {
  description = "The Azure subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "The Azure tenant ID"
  type        = string
}

variable "client_id" {
  description = "The Azure client ID (Service Principal)"
  type        = string
}

variable "client_secret" {
  description = "The Azure client secret (Service Principal Password)"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "hello-world-app-rg"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "aks_cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "hello-world-aks-cluster"
}

variable "node_count" {
  description = "Number of nodes in the node pool"
  type        = number
  default     = 1
}

variable "node_vm_size" {
  description = "VM size for the nodes"
  type        = string
  default     = "Standard_D2ps_v5"
}

variable "docker_image" {
  description = "Docker image to deploy"
  type        = string
  default     = "helloworldappregistry.azurecr.io/hello-world-repo:64"
}

variable "twilio_auth_token" {
  description = "Twilio Auth Token"
  type        = string
}

variable "application_port" {
  description = "Port on which the application runs"
  type        = number
  default     = 80
}

variable "trusted_ip_ranges" {
  description = "Trusted IP ranges for API server access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_log_analytics" {
  description = "Enable Log Analytics Workspace"
  type        = bool
  default     = true
}

variable "key_vault_name" {
  description = "Name of the Azure Key Vault"
  type        = string
  default     = "hello-world-key-vault-nu"
}

variable "key_vault_resource_group" {
  description = "Resource group for Key Vault"
  type        = string
  default     = "helloWorldApp"
}

variable "aks_version" {
  description = "AKS Kubernetes version"
  type        = string
  default     = "1.30"
}

variable "jenkins_ip" {
  description = "The IP of the CICD pipeline you're running on Jenkins"
  type        = string
}

variable "acr_name" {
  description = "The name of the repository that stores the image"
  type        = string
  default     = "helloWorldAppRegistry"
}
