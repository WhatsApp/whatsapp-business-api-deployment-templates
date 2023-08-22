#
# Copyright (c) Meta Platforms, Inc. and affiliates.

# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

# WhatsApp Business API Azure Template Version 1.0.1

resource "kubernetes_service" "webapp" {
  timeouts {
    create = "2m"
  }
  metadata {
    name   = "webapp"
    labels = { type = "webapp" }
  }
  spec {
    selector = {
      type = "webapp"
    }

    load_balancer_ip = azurerm_public_ip.waApi.ip_address

    port {
      port        = 443
      target_port = 443
    }

    type = "LoadBalancer"
  }
  depends_on = [kubernetes_deployment.webapp]
}

resource "kubernetes_service" "exporter-coreapp" {
  metadata {
    name   = "exporter-coreapp"
    labels = { type = "monitor" }
  }
  spec {
    selector = {
      type = "coreapp"
    }

    port {
      name        = "cadvisor"
      port        = 8080
      target_port = 8080
    }

    port {
      name        = "node-exporter"
      port        = 9100
      target_port = 9100
    }
  }
  depends_on = [kubernetes_deployment.monitor]
}

resource "kubernetes_service" "exporter-webapp" {
  metadata {
    name   = "exporter-webapp"
    labels = { type = "monitor" }
  }
  spec {
    selector = {
      type = "webapp"
    }

    port {
      name        = "cadvisor"
      port        = 8080
      target_port = 8080
    }

    port {
      name        = "node-exporter"
      port        = 9100
      target_port = 9100
    }
  }
  depends_on = [kubernetes_deployment.monitor]
}

resource "kubernetes_service" "mysqld-exporter" {
  metadata {
    name   = "mysqld-exporter"
    labels = { type = "monitor" }
  }
  spec {
    selector = {
      type = "monitor"
    }

    port {
      name        = "mysqld-exporter"
      port        = 9104
      target_port = 9104
    }
  }
  depends_on = [kubernetes_deployment.monitor]
}

resource "kubernetes_service" "prometheus" {
  metadata {
    name   = "prometheus"
    labels = { type = "monitor" }
  }
  spec {
    selector = {
      type = "monitor"
    }

    port {
      name        = "prometheus"
      port        = 9090
      target_port = 9090
    }
  }
  depends_on = [kubernetes_deployment.monitor]
}

resource "kubernetes_service" "monitor" {
  timeouts {
    create = "2m"
  }
  metadata {
    name   = "monitor"
    labels = { type = "monitor" }
  }
  spec {
    selector = {
      type = "monitor"
    }

    load_balancer_ip = azurerm_public_ip.waMon.ip_address

    port {
      name        = "grafana"
      port        = 3000
      target_port = 3000
    }

    port {
      name        = "prometheus"
      port        = 9090
      target_port = 9090
    }

    type = "LoadBalancer"
  }

  depends_on = [kubernetes_deployment.monitor]
}

resource "kubernetes_service" "db-headless" {
  metadata {
    name   = "db-headless"
    labels = { type = "db" }
  }
  spec {
    selector = {
      type = "db"
    }

    cluster_ip = "None"

    port {
      port        = 3306
      target_port = 3306
    }
  }
}

resource "kubernetes_service" "db" {
  metadata {
    name   = "db"
    labels = { type = "db" }
  }
  spec {
    selector = {
      type = "db"
    }

    port {
      name        = "db"
      port        = 3306
      target_port = 3306
    }
  }
}
