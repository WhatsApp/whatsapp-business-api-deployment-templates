#
# Copyright (c) Meta Platforms, Inc. and affiliates.

# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

# WhatsApp Business API Azure Template Version 1.0.0
resource "azurerm_public_ip" "waApi" {
  name                = "${module.naming.public_ip.name}-waApi"
  resource_group_name = "${module.naming.resource_group.name_unique}-aks-node"
  location            = azurerm_resource_group.waApi.location
  domain_name_label   = "${var.name-prefix}-${var.owner}-web-lb"
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    owner = var.owner
  }

}

resource "azurerm_public_ip" "waMon" {
  name                = "${module.naming.public_ip.name}-waMon"
  resource_group_name = "${module.naming.resource_group.name_unique}-aks-node"
  location            = azurerm_resource_group.waApi.location
  domain_name_label   = "${var.name-prefix}-${var.owner}-mon-lb"
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    owner = var.owner
  }
}
