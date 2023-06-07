#
# Copyright (c) Meta Platforms, Inc. and affiliates.

# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

# WhatsApp Business API GCP Template Version 1.0.0

resource "google_container_node_pool" "monitor" {
  name       = "monitor-node-pool"
  location   = var.zone
  cluster    = google_container_cluster.waApi.name
  node_count = 2
  node_config {
    preemptible  = false
    machine_type = "n2-highcpu-2"
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    labels = {
      type = "monitor"
    }
    tags = [var.owner]

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

resource "kubernetes_persistent_volume_claim" "prometheus" {
  count = var.nfs-pvc-creation-complete ? 1 : 0
  timeouts {
    create = "5m"

  }
  metadata {
    name        = "prometheus"
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "10Gi"
      }
    }
    storage_class_name = kubernetes_storage_class.prometheus.metadata.0.name
  }

  depends_on = [kubernetes_storage_class.prometheus]
}

resource "kubernetes_storage_class" "prometheus" {
  metadata {
    name = "prometheus"
  }

  storage_provisioner = "pd.csi.storage.gke.io"
  volume_binding_mode    = "Immediate"
  allow_volume_expansion = true

  parameters = {
    type = "pd-standard"
  }
}

resource "kubernetes_persistent_volume_claim" "grafana" {
  count = var.nfs-pvc-creation-complete ? 1 : 0
  timeouts {

    create = "5m"

  }
  metadata {
    name        = "grafana"
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "10Gi"
      }
    }
    storage_class_name = kubernetes_storage_class.grafana.metadata.0.name
  }

  depends_on = [kubernetes_storage_class.grafana]
}

resource "kubernetes_storage_class" "grafana" {
  metadata {
    name = "grafana"
  }

  storage_provisioner = "pd.csi.storage.gke.io"
  volume_binding_mode    = "Immediate"
  allow_volume_expansion = true

  parameters = {
    type = "pd-standard"
  }
}

resource "kubernetes_deployment" "monitor" {
  count = var.nfs-pvc-creation-complete ? 1 : 0
  depends_on = [google_container_node_pool.monitor]
  timeouts {
    create = "10m"
    update = "5m"
    delete = "1m"
  }
  metadata {
    name = "monitor"
    labels = {
      type = "monitor"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        type = "monitor"
      }
    }

    template {
      metadata {
        name   = "monitor"
        labels = { type = "monitor" }
      }

      spec {
        affinity {
          pod_anti_affinity {
            required_during_scheduling_ignored_during_execution {
              label_selector {
                match_expressions {
                  key      = "type"
                  operator = "In"
                  values   = ["monitor"]
                }
              }
              topology_key = "kubernetes.io/hostname"
            }
          }
          node_affinity {
            required_during_scheduling_ignored_during_execution {
              node_selector_term {
                match_expressions {
                  key      = "type"
                  operator = "In"
                  values   = ["monitor"]
                }
              }
            }
          }
        }

        volume {
          name = local.prom-vol
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.prometheus.0.metadata.0.name
          }
        }

        volume {
          name = local.grafana-vol
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.grafana.0.metadata.0.name
          }
        }

        container {
          image = "prom/mysqld-exporter:v0.10.0"
          name  = "mysqld-exporter"

          resources {
            requests = {
              memory = "100M"
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.db.metadata.0.name
            }
          }

          port {
            container_port = 9104
          }
        }

        container {
          name  = "prometheus"
#
#          security_context {
#            run_as_user = 0
#          }

          volume_mount {
            name       = local.prom-vol
            mount_path = local.prom-vol-container-path
          }

          resources {
            requests = {
              memory = "100Mi"
            }
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.mon-prom[0].metadata.0.name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.mon-prom.metadata.0.name
            }
          }

          port {
            container_port = 9090
          }
        }


        container {
          name  = "grafana"

          volume_mount {
            name       = local.grafana-vol
            mount_path = local.grafana-vol-container-path
          }

          resources {
            requests = {
              memory = "100Mi"
            }
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.mon-graf.metadata.0.name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.mon-graf.metadata.0.name
            }
          }

          port {
            container_port = 3000
          }
        }

      }
    }

    strategy {
      type = "RollingUpdate"

      rolling_update {
        max_unavailable = "1"
        max_surge       = "1"
      }
    }
    revision_history_limit = 10
  }
}

resource "kubernetes_daemonset" "exporter" {
  count = var.nfs-pvc-creation-complete ? 1 : 0
  metadata {
    name = "exporter"
    labels = {
      type = "exporter"
    }
  }

  spec {
    selector {
      match_labels = {
        type = "exporter"
      }
    }

    template {
      metadata {
        labels = {
          type = "exporter"
        }
      }

      spec {
        affinity {
          node_affinity {
            required_during_scheduling_ignored_during_execution {
              node_selector_term {
                match_expressions {
                  key      = "type"
                  operator = "In"
                  values   = ["coreapp", "webapp"]
                }
              }
            }
          }
        }

        volume {
          name = local.root-vol
          host_path {
            path = local.root-vol-src
          }
        }

        volume {
          name = local.tmpfs-vol
          host_path {
            path = local.tmpfs-vol-src
          }
        }

        volume {
          name = local.sys-vol
          host_path {
            path = local.sys-vol-src
          }
        }

        volume {
          name = local.docker-vol
          host_path {
            path = local.docker-vol-src
          }
        }

        volume {
          name = local.device-vol
          host_path {
            path = local.device-vol-src
          }
        }

        volume {
          name = local.proc-vol
          host_path {
            path = local.proc-vol-src
          }
        }

        container {
          image = "google/cadvisor:v0.30.2"
          name  = "cadvisor"

          volume_mount {
            name       = local.root-vol
            mount_path = local.root-vol-container-path
          }

          volume_mount {
            name       = local.sys-vol
            mount_path = local.sys-vol-container-path
          }

          volume_mount {
            name       = local.docker-vol
            mount_path = local.docker-vol-container-path
          }

          volume_mount {
            name       = local.device-vol
            mount_path = local.device-vol-container-path
          }

          volume_mount {
            name       = local.tmpfs-vol
            mount_path = local.tmpfs-vol-container-path
          }

          resources {
            requests = {
              memory = "128Mi"
            }
          }

          port {
            container_port = 8080
          }
        }

        container {
          image = "prom/node-exporter:v0.16.0"
          name  = "node-exporter"

          volume_mount {
            name       = local.root-vol
            mount_path = local.root-vol-container-path
            read_only  = true
          }

          volume_mount {
            name       = local.sys-vol
            mount_path = local.sys-vol-container-path
            read_only  = true
          }

          volume_mount {
            name       = local.proc-vol
            mount_path = local.proc-vol-container-path
            read_only  = true
          }

          resources {
            requests = {
              memory = "32Mi"
            }
          }

          port {
            container_port = 9100
          }
        }

      }
    }
  }
}


resource "kubernetes_service" "exporter-coreapp" {
  count = var.nfs-pvc-creation-complete ? 1 : 0
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
  count = var.nfs-pvc-creation-complete ? 1 : 0
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
  count = var.nfs-pvc-creation-complete ? 1 : 0
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
  count = var.nfs-pvc-creation-complete ? 1 : 0
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
  count = var.nfs-pvc-creation-complete ? 1 : 0
  timeouts {
    create = "10m"
  }
  metadata {
    name   = "monitor"
    labels = { type = "monitor" }
  }
  spec {
    selector = {
      type = "monitor"
    }

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
