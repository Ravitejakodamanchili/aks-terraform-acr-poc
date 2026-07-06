terraform {
  required_version = ">= 1.4.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "7e9ae0c1-f518-43cc-83ae-7d9a918ba962"
}

# Existing Resource Group
data "azurerm_resource_group" "rg" {
  name = "Ind-Azure-PS-Raviteja"
}

# Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "ravitejaacr20260702"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  sku           = "Basic"
  admin_enabled = false
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-raviteja-poc"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  dns_prefix          = "aksraviteja"

  sku_tier = "Free"

  default_node_pool {
    name       = "system"
    node_count = 1
    vm_size    = "Standard_B2s"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "POC"
    Owner       = "Raviteja"
  }
}

# Grant AKS permission to pull images from ACR
resource "azurerm_role_assignment" "acrpull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id

  depends_on = [
    azurerm_kubernetes_cluster.aks,
    azurerm_container_registry.acr
  ]
}

output "aks_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "acr_name" {
  value = azurerm_container_registry.acr.name
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}