#
# Copyright (c) Meta Platforms, Inc. and affiliates.

# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

# WhatsApp Business API Azure Template Version 1.0.0

# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.96.0"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

provider "kubernetes" {
  config_path            = "~/.kube/config"
  host                   = azurerm_kubernetes_cluster.waApi.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.waApi.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.waApi.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.waApi.kube_config.0.cluster_ca_certificate)
}

resource "random_id" "name" {
  keepers = {
    owner = "${var.owner}"
  }
  byte_length = 8
}

module "naming" {
  source      = "Azure/naming/azurerm"
  suffix      = ["${var.name-prefix}", "${var.owner}"]
  unique-seed = random_id.name.hex
}

resource "azurerm_resource_group" "waNet" {
  name     = module.naming.resource_group.name
  location = var.location
  tags = {
    "owner" = var.owner
  }
}

resource "azurerm_resource_group" "waApi" {
  name     = module.naming.resource_group.name
  location = var.location
  tags = {
    "owner" = var.owner
  }
}

resource "azurerm_log_analytics_workspace" "waApi" {
  name                = module.naming.log_analytics_workspace.name
  location            = azurerm_resource_group.waApi.location
  resource_group_name = azurerm_resource_group.waApi.name
  sku                 = "standalone"
  retention_in_days   = 30
}

output "client_certificate" {
  value = azurerm_kubernetes_cluster.waApi.kube_config.0.client_certificate
}

output "web_server_name" {
  value = azurerm_public_ip.waApi.fqdn
}

output "monitor_server_name" {
  value = azurerm_public_ip.waMon.fqdn
}

# output "db_server_name" {
#   value = azurerm_mysql_flexible_server.waApi.fqdn
# }

# output "db_server_name_single_server" {
#   value = azurerm_mysql_server.waApi.fqdn
# }

output "kube_config" {
  value = azurerm_kubernetes_cluster.waApi.kube_config_raw

  sensitive = true
}
