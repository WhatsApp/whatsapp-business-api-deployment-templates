#
# Copyright (c) Meta Platforms, Inc. and affiliates.

# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

# WhatsApp Business API GCP Template Version 1.0.0
locals {
  db_host_name = "db"
  webapp_host_ip = var.nfs-pvc-creation-complete ? kubernetes_service.webapp[0].status.0.load_balancer.0.ingress.0.ip:null
}

resource "kubernetes_config_map" "mysql-init" {
  metadata {
    name = "db-user"
  }

  data = {
    # "add-user.sh" = "${file("scripts/add-user.sh")}"
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

resource "kubernetes_config_map" "env" {
  metadata {
    name = "config-env"
  }

  data = {
    COREAPP_EXTERNAL_PORTS = "6250,6251,6252,6253"
    WA_DB_SSL_CA           = var.DBConnCA
    WA_DB_PORT             = "3306"
    WA_DB_HOSTNAME                = local.db_host_name
    WA_DB_PERSISTENT              = "1"
    WA_DB_ENGINE                  = "MYSQL"
    WA_CONFIG_ON_DB               = "1"
    WA_RUNNING_ENV                = "GCP"
    WA_APP_MULTICONNECT           = "1"
    WA_DB_CONNECTION_IDLE_TIMEOUT = "180000"
  }
}

resource "kubernetes_config_map" "master" {
  metadata {
    name = "config-master"
  }

  data = {
    WA_MASTER_NODE = "1"
  }
}

resource "kubernetes_config_map" "mon-prom" {
  count = var.nfs-pvc-creation-complete ? 1 : 0
  metadata {
    name = "config-mon-prom"
  }

  data = {
    WA_WEB_ENDPOINT                      = "${local.webapp_host_ip}:443"
    WA_WEB_USERNAME                      = var.mon-web-username
    WA_MYSQLD_EXPORTER_ENDPOINT          = "mysqld-exporter:9104"
    WA_CORE_ENDPOINT                     = local.webapp_host_ip
    WA_NODE_EXPORTER_PORT                = "9100"
    WA_CADVISOR_PORT                     = "8080"
    WA_PROMETHEUS_STORAGE_TSDB_RETENTION = "15d"
  }
}

resource "kubernetes_config_map" "mon-graf" {
  metadata {
    name = "config-mon-graf"
  }
  data = {
    WA_PROMETHEUS_ENDPOINT = "http://prometheus:9090"
    GF_SMTP_ENABLED        = var.mon-smtp-enabled
    GF_SMTP_HOST           = var.mon-smtp-host
    GF_SMTP_USER           = var.mon-smtp-username
    GF_SMTP_SKIP_VERIFY    = "1"
  }
}
