#
# Copyright (c) Meta Platforms, Inc. and affiliates.

# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

# WhatsApp Business API Azure Template Version 1.0.0

resource "kubernetes_persistent_volume_claim" "media-share" {
  metadata {
    name = "media-share"
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "100Gi"
      }
    }

    storage_class_name = kubernetes_storage_class.media-share.metadata.0.name
  }

  depends_on = [azurerm_role_assignment.waApi]
}

resource "kubernetes_storage_class" "media-share" {
  metadata {
    name = "media-share"
  }
  # storage_provisioner = "kubernetes.io/azure-file"
  storage_provisioner = "file.csi.azure.com"
  reclaim_policy      = "Retain"
  parameters = {
    protocol = "nfs"
    skuName  = "Premium_LRS"
    location = var.location
  }
  #mount_options = ["file_mode=0666", "dir_mode=0777", "mfsymlinks", "uid=0", "gid=0", "cache=strict"] ///smb option only
  mount_options = ["nconnect=8", "nfsvers=4.1", "rsize=1048576", "wsize=1048576", "hard", "actimeo=120", "timeo=600", "retrans=2"] ///nfs option only
}


resource "kubernetes_persistent_volume_claim" "db" {
  metadata {
    name        = "db"
    labels      = {}
    annotations = {}
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "64Gi"
      }
    }

    storage_class_name = kubernetes_storage_class.db.metadata.0.name
  }
}

resource "kubernetes_storage_class" "db" {
  metadata {
    name = "db"
  }

  storage_provisioner    = "disk.csi.azure.com"
  reclaim_policy         = "Retain"
  volume_binding_mode    = "Immediate"
  allow_volume_expansion = true

  parameters = {
    skuName     = "UltraSSD_LRS"
    kind        = "managed"
    cachingMode = "None"
    diskIopsReadWrite : var.map_db_iops[var.throughput]
    diskMbpsReadWrite : var.map_db_throughput[var.throughput]
  }
}
