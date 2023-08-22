#
# Copyright (c) Meta Platforms, Inc. and affiliates.

# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

# WhatsApp Business API Azure Template Version 1.0.1

locals {
  # data_source_name = "${var.dbusername}:${var.dbpassword}@(${azurerm_mysql_flexible_server.waApi.fqdn}:3306)/" #flexible server
  # data_source_name = "${var.dbusername}@${azurerm_mysql_server.waApi.fqdn}:${var.dbpassword}@(${azurerm_mysql_server.waApi.fqdn}:3306)/?allowNativePasswords=true" #single server
  data_source_name = "${var.dbusername}:${var.dbpassword}@(${kubernetes_service.db.metadata.0.name}:3306)/" #vm server
  # wa_db_username   =  "${var.dbusername}@${azurerm_mysql_server.waApi.fqdn}" #single server
  wa_db_username = var.dbusername #vm server && flexible server
}
resource "kubernetes_secret" "env" {
  metadata {
    name = "secret-env"
    # namespace = kubernetes_namespace.deployment.metadata.0.name
  }

  data = {
    WA_DB_USERNAME = local.wa_db_username
    WA_DB_PASSWORD = var.dbpassword
  }
}

resource "kubernetes_secret" "db" {
  metadata {
    name = "secret-db"
    # namespace = kubernetes_namespace.deployment.metadata.0.name
  }

  data = {
    DATA_SOURCE_NAME = local.data_source_name
  }
}

resource "kubernetes_secret" "mon-prom" {
  metadata {
    name = "secret-mon-prom"
    # namespace = kubernetes_namespace.deployment.metadata.0.name
  }

  data = {
    WA_WEB_PASSWORD = var.wabiz-web-password
  }
}

resource "kubernetes_secret" "mon-graf" {
  metadata {
    name = "secret-mon-graf"
    # namespace = kubernetes_namespace.deployment.metadata.0.name
  }

  data = {
    GF_SECURITY_ADMIN_PASSWORD = var.mon-web-password
    GF_SMTP_PASSWORD           = var.mon-smtp-password
  }
}
