#
# Copyright (c) Meta Platforms, Inc. and affiliates.

# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

# WhatsApp Business API Azure Template Version 1.0.0

resource "azurerm_virtual_network" "waNet" {
  name                = module.naming.virtual_network.name_unique
  location            = azurerm_resource_group.waNet.location
  resource_group_name = azurerm_resource_group.waNet.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet-main" {
  name                                           = "${module.naming.subnet.name_unique}-main"
  resource_group_name                            = azurerm_resource_group.waNet.name
  address_prefixes                               = ["10.0.128.0/20"]
  virtual_network_name                           = azurerm_virtual_network.waNet.name
  service_endpoints                              = ["Microsoft.Storage", "Microsoft.Sql"]
  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_subnet" "subnet-ha" {
  name                                           = "${module.naming.subnet.name_unique}-ha"
  resource_group_name                            = azurerm_resource_group.waNet.name
  address_prefixes                               = ["10.0.144.0/20"]
  virtual_network_name                           = azurerm_virtual_network.waNet.name
  enforce_private_link_endpoint_network_policies = true
}

# for flexible server
resource "azurerm_subnet" "subnet-main-db" {
  name                 = "${module.naming.subnet.name_unique}-main-db"
  resource_group_name  = azurerm_resource_group.waNet.name
  virtual_network_name = azurerm_virtual_network.waNet.name
  address_prefixes     = ["10.0.160.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

#for single server and vm+mysql
resource "azurerm_subnet" "subnet-main-db-ss" {
  name                                           = "${module.naming.subnet.name_unique}-main-db-ss"
  resource_group_name                            = azurerm_resource_group.waNet.name
  virtual_network_name                           = azurerm_virtual_network.waNet.name
  address_prefixes                               = ["10.0.161.0/24"]
  service_endpoints                              = ["Microsoft.Storage"]
  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_network_watcher" "waNet" {
  name                = "production-nwwatcher"
  location            = azurerm_resource_group.waNet.location
  resource_group_name = azurerm_resource_group.waNet.name
}
