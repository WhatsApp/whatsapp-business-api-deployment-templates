#
# Copyright (c) Meta Platforms, Inc. and affiliates.

# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

# WhatsApp Business API Azure Template Version 1.0.0
locals {
  # db_host_name = azurerm_mysql_flexible_server.waApi.fqdn #flexible server
  # db_host_name = azurerm_mysql_server.waApi.fqdn #single server
  db_host_name = kubernetes_service.db.metadata.0.name #vm server
}
resource "kubernetes_config_map" "env" {
  metadata {
    name = "config-env"
    # namespace = kubernetes_namespace.deployment.metadata.0.name
  }

  data = {
    COREAPP_EXTERNAL_PORTS = "6250,6251,6252,6253"
    WA_DB_SSL_CA           = var.DBConnCA
    WA_DB_PORT             = "3306"
    # COREAPP_HOSTNAME              = ""
    WA_DB_HOSTNAME                = local.db_host_name
    WA_DB_PERSISTENT              = "1"
    WA_DB_ENGINE                  = "MYSQL"
    WA_CONFIG_ON_DB               = "1"
    WA_RUNNING_ENV                = "AZURE"
    WA_APP_MULTICONNECT           = "1"
    WA_DB_CONNECTION_IDLE_TIMEOUT = "180000"
  }
}

resource "kubernetes_config_map" "mon-prom" {
  metadata {
    name = "config-mon-prom"
    # namespace = kubernetes_namespace.deployment.metadata.0.name
  }

  data = {
    WA_WEB_ENDPOINT                      = "${azurerm_public_ip.waApi.fqdn}:443"
    WA_WEB_USERNAME                      = var.wabiz-web-username
    WA_MYSQLD_EXPORTER_ENDPOINT          = "mysqld-exporter:9104"
    WA_CORE_ENDPOINT                     = azurerm_public_ip.waApi.fqdn
    WA_NODE_EXPORTER_PORT                = "9100"
    WA_CADVISOR_PORT                     = "8080"
    WA_PROMETHEUS_STORAGE_TSDB_RETENTION = "15d"
  }
}

resource "kubernetes_config_map" "mon-graf" {
  metadata {
    name = "config-mon-graf"
    # namespace = kubernetes_namespace.deployment.metadata.0.name
  }

  data = {
    WA_PROMETHEUS_ENDPOINT = "http://prometheus:9090"
    GF_SMTP_ENABLED        = var.mon-smtp-enabled
    GF_SMTP_HOST           = var.mon-smtp-host
    GF_SMTP_USER           = var.mon-smtp-username
    GF_SMTP_SKIP_VERIFY    = "1"
  }
}

resource "kubernetes_config_map" "master" {
  metadata {
    name = "config-master"
    # namespace = kubernetes_namespace.deployment.metadata.0.name
  }

  data = {
    WA_MASTER_NODE = "1"
  }
}

resource "kubernetes_config_map" "mysql-init" {
  metadata {
    name = "db-user"
    # namespace = kubernetes_namespace.deployment.metadata.0.name
  }

  data = {
    "copy-cnf.sh" = "${file("scripts/copy-cnf.sh")}"
    "my.cnf"      = "${file("scripts/my.cnf")}"
  }
}

resource "kubernetes_config_map" "mysql-initdb" {
  metadata {
    name = "mysql-initdb-config"
  }

  data = {
    "add-user.sh" = "${file("scripts/add-user.sh")}"
  }
}
