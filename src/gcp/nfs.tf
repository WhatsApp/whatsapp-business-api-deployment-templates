#
# Copyright (c) Meta Platforms, Inc. and affiliates.

# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

# WhatsApp Business API GCP Template Version 1.0.0

resource "google_container_node_pool" "nfs" {
  name       = "nfs-node-pool"
  location   = var.zone
  cluster    = google_container_cluster.waApi.name
  node_count = 2

  node_config {
    preemptible  = false
    machine_type = var.map_coreapp_class[var.message_type][var.throughput]
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    labels = {
      type = "nfs"
    }
    tags = [var.owner]

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

resource "kubernetes_persistent_volume_claim" "nfs_store" {
  metadata {
    name = "nfs-store"
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "200Gi"
      }
    }
    storage_class_name = kubernetes_storage_class.nfs_store.metadata.0.name
  }

    depends_on = [kubernetes_storage_class.nfs_store]
}

resource "kubernetes_storage_class" "nfs_store" {
  metadata {
    name = "nfs-store"
  }

  storage_provisioner = "pd.csi.storage.gke.io"
  reclaim_policy         = "Retain"
  volume_binding_mode    = "Immediate"
  allow_volume_expansion = true

  parameters = {
    type = "pd-ssd"
  }
}

resource "kubernetes_deployment" "nfs_server" {
  metadata {
    name = "nfs-server"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        type = "nfs-server"
      }
    }

    template {
      metadata {
        labels = {
          type= "nfs-server"
        }
      }

      spec {

        volume {
          name = "nfsstore"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.nfs_store.metadata.0.name
          }
        }

        affinity {
          pod_anti_affinity {
            required_during_scheduling_ignored_during_execution {
              label_selector {
                match_expressions {
                  key      = "type"
                  operator = "In"
                  values   = ["nfs-server"]
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
                  values   = ["nfs"]
                }
              }
            }
          }
        }

        container {
          name  = "nfs-server"
          image = "gcr.io/google_containers/volume-nfs:0.8"

          port {
            name           = "nfs"
            container_port = 2049
          }

          port {
            name           = "mountd"
            container_port = 20048
          }

          port {
            name           = "rpcbind"
            container_port = 111
          }

          volume_mount {
            name       = "nfsstore"
            mount_path = "/exports"
          }

          security_context {
            privileged = true
          }
        }
      }
    }
  }
  depends_on = [google_container_node_pool.nfs]
}


resource "kubernetes_service" "nfs_server" {
  metadata {
    name = "nfs-server"
  }

  spec {
    port {
      name = "nfs"
      port = 2049
    }

    port {
      name = "mountd"
      port = 20048
    }

    port {
      name = "rpcbind"
      port = 111
    }

    selector = {
      type = "nfs-server"
    }
  }
  depends_on = [kubernetes_deployment.nfs_server]
}
