#
# Copyright (c) Meta Platforms, Inc. and affiliates.

# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

# WhatsApp Business API Azure Template Version 1.0.0
resource "azurerm_kubernetes_cluster" "waApi" {
  name                = module.naming.kubernetes_cluster.name_unique
  location            = azurerm_resource_group.waApi.location
  resource_group_name = azurerm_resource_group.waApi.name
  node_resource_group = "${module.naming.resource_group.name_unique}-aks-node"
  dns_prefix          = "${var.name-prefix}-${var.owner}"

  default_node_pool {
    availability_zones = [
      "1",
    ]
    enable_auto_scaling          = true
    enable_host_encryption       = false
    enable_node_public_ip        = false
    fips_enabled                 = false
    kubelet_disk_type            = "OS"
    max_count                    = 1
    max_pods                     = 30
    min_count                    = 1
    name                         = "sys"
    node_count                   = 1
    only_critical_addons_enabled = false
    os_disk_size_gb              = 128
    os_disk_type                 = "Managed"
    os_sku                       = "Ubuntu"
    tags = {
      "owner" = var.owner
    }
    type              = "VirtualMachineScaleSets"
    ultra_ssd_enabled = false
    vm_size           = var.k8s-vm-class
    vnet_subnet_id    = azurerm_subnet.subnet-main.id
  }

  network_profile {
    network_plugin     = "azure"
    service_cidr       = "10.0.176.0/20"
    docker_bridge_cidr = "10.0.176.0/20"
    dns_service_ip     = "10.0.176.3"
  }

  identity {
    type = "SystemAssigned"
  }

  linux_profile {
    admin_username = "azureuser"
    ssh_key {
      key_data = file(var.ssh-pub-key)
    }
  }

  tags = {
    owner = var.owner
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "db" {
  availability_zones = [
    "2",
  ]
  enable_auto_scaling    = false
  enable_host_encryption = false
  enable_node_public_ip  = false
  fips_enabled           = false
  kubelet_disk_type      = "OS"
  kubernetes_cluster_id  = azurerm_kubernetes_cluster.waApi.id
  max_count              = 0
  max_pods               = 30
  min_count              = 0
  mode                   = "User"
  name                   = "db"
  node_count             = 1
  node_labels            = { "type" : "db" }
  os_disk_size_gb        = 32
  os_disk_type           = "Managed"
  os_sku                 = "Ubuntu"
  os_type                = "Linux"
  priority               = "Regular"
  scale_down_mode        = "Delete"
  spot_max_price         = -1
  ultra_ssd_enabled      = true
  vm_size                = var.map_db_class[var.throughput]
  vnet_subnet_id         = azurerm_subnet.subnet-main-db-ss.id

  tags = {
    owner = var.owner
  }

}

resource "azurerm_kubernetes_cluster_node_pool" "coreapp" {
  availability_zones = [
    "1",
  ]
  enable_auto_scaling    = false
  enable_host_encryption = false
  enable_node_public_ip  = true
  fips_enabled           = false
  kubelet_disk_type      = "OS"
  kubernetes_cluster_id  = azurerm_kubernetes_cluster.waApi.id
  max_count              = 0
  max_pods               = 30
  min_count              = 0
  mode                   = "User"
  name                   = "coreapp"
  node_count             = var.map_shards_count[var.throughput] + 1
  node_labels            = { "type" : "coreapp" }
  os_disk_size_gb        = 32
  os_disk_type           = "Managed"
  os_sku                 = "Ubuntu"
  os_type                = "Linux"
  priority               = "Regular"
  scale_down_mode        = "Delete"
  spot_max_price         = -1
  ultra_ssd_enabled      = false
  vm_size                = var.map_coreapp_class[var.message_type][var.throughput]
  vnet_subnet_id         = azurerm_subnet.subnet-main.id

  tags = {
    owner = var.owner
  }

  # lifecycle {
  #   ignore_changes = [node_count]
  # }

  depends_on = [
    azurerm_kubernetes_cluster_node_pool.db, azurerm_kubernetes_cluster_node_pool.webapp
  ]

}

resource "azurerm_kubernetes_cluster_node_pool" "webapp" {
  availability_zones = [
    "1",
  ]
  enable_auto_scaling    = false
  enable_host_encryption = false
  enable_node_public_ip  = true
  fips_enabled           = false
  kubelet_disk_type      = "OS"
  kubernetes_cluster_id  = azurerm_kubernetes_cluster.waApi.id
  max_count              = 0
  max_pods               = 30
  min_count              = 0
  mode                   = "User"
  name                   = "webapp"
  node_count             = var.map_web_server_count[var.throughput]
  node_labels            = { "type" : "webapp" }
  os_disk_size_gb        = 32
  os_disk_type           = "Managed"
  os_sku                 = "Ubuntu"
  os_type                = "Linux"
  priority               = "Regular"
  scale_down_mode        = "Delete"
  spot_max_price         = -1
  ultra_ssd_enabled      = false
  vm_size                = "Standard_F2s_v2"
  vnet_subnet_id         = azurerm_subnet.subnet-main.id

  tags = {
    owner = var.owner
  }

  depends_on = [
    azurerm_kubernetes_cluster_node_pool.db
  ]

}

resource "azurerm_kubernetes_cluster_node_pool" "monitor" {
  availability_zones = [
    "1",
  ]
  enable_auto_scaling    = false
  enable_host_encryption = false
  enable_node_public_ip  = true
  fips_enabled           = false
  kubelet_disk_type      = "OS"
  kubernetes_cluster_id  = azurerm_kubernetes_cluster.waApi.id
  max_count              = 0
  max_pods               = 30
  min_count              = 0
  mode                   = "User"
  name                   = "monitor"
  node_count             = 1
  node_labels            = { "type" : "monitor" }
  os_disk_size_gb        = 128
  os_disk_type           = "Managed"
  os_sku                 = "Ubuntu"
  os_type                = "Linux"
  priority               = "Regular"
  scale_down_mode        = "Delete"
  spot_max_price         = -1
  ultra_ssd_enabled      = false
  vm_size                = "Standard_B2ms"
  vnet_subnet_id         = azurerm_subnet.subnet-main.id

  tags = {
    owner = var.owner
  }
}
