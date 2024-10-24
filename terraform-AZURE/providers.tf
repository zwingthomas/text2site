terraform {
  required_version = ">= 0.13"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }

  backend "azurerm" {
    resource_group_name   = "helloWorldApp"
    storage_account_name  = "zwingerbackend"
    container_name        = "zwinger"
    key                   = "terraform.tfstate"   # Name of the state file
  }
}

provider "azurerm" {
  features {}
}
