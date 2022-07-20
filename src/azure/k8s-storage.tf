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
        storage = "1Gi"
      }
    }

    storage_class_name = kubernetes_storage_class.media-share.metadata.0.name
  }
}

resource "kubernetes_storage_class" "media-share" {
  metadata {
    name = "media-share"
  }
  storage_provisioner = "kubernetes.io/azure-file"
  reclaim_policy      = "Retain"
  parameters = {
    skuName  = "Standard_LRS"
    location = var.location
  }
  mount_options = ["file_mode=0400", "dir_mode=0600", "mfsymlinks", "uid=0", "gid=0", "cache=strict"]
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
