#
# Copyright (c) Meta Platforms, Inc. and affiliates.

# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

# WhatsApp Business API GCP Template Version 1.0.0

resource "kubernetes_persistent_volume_claim" "db" {
  metadata {
    name        = "db"
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "800Gi"
      }
    }

    storage_class_name = kubernetes_storage_class.db.metadata.0.name
  }

    depends_on = [kubernetes_storage_class.db]
}

resource "kubernetes_storage_class" "db" {
  metadata {
    name = "db"
  }

  storage_provisioner = "pd.csi.storage.gke.io"
  reclaim_policy         = "Retain"
  volume_binding_mode    = "Immediate"
  allow_volume_expansion = true

  parameters = {
    type = "pd-ssd"
  }
}

#extreme-disk
# resource "google_compute_disk" "extreme-disk" {
#   name = "extreme-disk"
#   type = "pd-extreme"
#   zone = var.zone
#   labels = {
#     environment = "db"
#   }
#   #GB
#   size = 500
#   provisioned_iops          = 15000
#   depends_on = [google_container_node_pool.db]
# }

# resource "kubernetes_persistent_volume" "extreme-disk" {
#   timeouts {
#     create = "3m"
#   }
#   metadata {
#     name = "extreme-disk"
#   }
#   spec {
#     capacity = {
#       storage = "500Gi"
#     }
#     storage_class_name = "pd-extreme"
#     access_modes = ["ReadWriteOnce"]
#     persistent_volume_source {
#       gce_persistent_disk {
#         pd_name = google_compute_disk.extreme-disk.name
#         fs_type = "ext4"
#       }
#     }
#   }
#   depends_on = [google_compute_disk.extreme-disk]
# }

# resource "kubernetes_persistent_volume_claim" "extreme-disk" {
#   timeouts {
#     create = "3m"
#   }
#   metadata {
#     name        = "extreme-disk"
#   }
#   spec {
#     access_modes = ["ReadWriteOnce"]
#     resources {
#       requests = {
#         storage = "500Gi"
#       }
#     }
#     storage_class_name = "pd-extreme"
#     volume_name = kubernetes_persistent_volume.extreme-disk.metadata.0.name
#   }
#   depends_on = [kubernetes_persistent_volume.extreme-disk]
# }
