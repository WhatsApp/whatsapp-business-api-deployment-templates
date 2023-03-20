#
# Copyright (c) Meta Platforms, Inc. and affiliates.

# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

# WhatsApp Business API GCP Template Version 1.0.0

# provider "kubectl" {
#   config_path            = "~/.kube/config"
#   host                   = "https://${google_container_cluster.waApi.endpoint}"
#   username = var.gke_username
#   password = var.gke_password
#   client_certificate     = base64decode(google_container_cluster.waApi.master_auth.0.client_certificate)
#   client_key             = base64decode(google_container_cluster.waApi.master_auth.0.client_key)
#   cluster_ca_certificate = base64decode(google_container_cluster.waApi.master_auth.0.cluster_ca_certificate)
# }

# #Use raw yaml due to issue in terraform:  https://github.com/hashicorp/terraform-provider-kubernetes/issues/1379?fbclid=IwAR2k0P0YSI1Uw8XNJfCfdNoqn3GAJjgDD1r6buRuvSUOss-uoG5pmi6Wr30
# resource "kubectl_manifest" "media_share_pv" {
#   yaml_body = <<YAML
# apiVersion: v1
# kind: PersistentVolume
# metadata:
#   name: nfs-pv-test
# spec:
#   capacity:
#     storage: 10Gi
#   accessModes:
#     - ReadWriteMany
#   nfs:
#     server: nfs-server.default.svc.cluster.local
#     path: "/"
# YAML
#   depends_on = [kubernetes_service.nfs_server]
# }

# resource "kubectl_manifest" "media_share_pvc" {
#   yaml_body = <<YAML
# apiVersion: v1
# kind: PersistentVolumeClaim
# apiVersion: v1
# metadata:
#   name: nfs-pvc-test
# spec:
#   accessModes:
#     - ReadWriteMany
#   storageClassName: ""
#   resources:
#     requests:
#       storage: 1Gi
# YAML

#   depends_on = [kubectl_manifest.media_share_pv]
# }



#Comment this code, due to issue in terraform https://github.com/hashicorp/terraform-provider-kubernetes/issues/1379?fbclid=IwAR2k0P0YSI1Uw8XNJfCfdNoqn3GAJjgDD1r6buRuvSUOss-uoG5pmi6Wr30
#Which caused storage class can not be set as "" empty

# resource "kubernetes_persistent_volume" "media-share" {
#   timeouts {
#     create = "2m"
#   }

#   depends_on = [kubernetes_service.nfs_server]
#   metadata {
#     name = "media-share"
#   }
#   spec {
#     capacity = {
#       storage = "300Gi"
#     }
#     access_modes       = ["ReadWriteMany"]
#     persistent_volume_source {
#       nfs {
#         server = kubernetes_service.nfs_server.metadata.0.name
#         path   = "/"
#       }
#     }
#   }
# }

# resource "kubernetes_persistent_volume_claim" "media-share" {
#   timeouts {
#     create = "2m"
#   }
#   metadata {
#     name = "media-share"
#   }
#   spec {
#     access_modes = ["ReadWriteMany"]
#     resources {
#       requests = {
#         storage = "10Gi"
#       }
#     }

#     # storage_class_name = kubernetes_storage_class.media-share.metadata.0.name
#     storage_class_name =  "nil"
#     # storage_class_name =  "default"
#   }
# }
