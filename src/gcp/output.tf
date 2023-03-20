
#
# Copyright (c) Meta Platforms, Inc. and affiliates.

# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

# WhatsApp Business API GCP Template Version 1.0.0

output "throughput" {
  value = var.throughput
}

output "app-machine-type" {
  value =  var.map_coreapp_class[var.message_type][var.throughput]
}

output "db-machine-type" {
  value =  var.map_db_class[var.throughput]
}

output "number_of_shards" {
  value = var.map_shards_count[var.throughput]
}

output "webapp_lb_ip" {
  value = kubernetes_service.webapp[*].status.0.load_balancer.0.ingress.0.ip
}

output "monitor_lb_ip" {
  value = kubernetes_service.monitor[*].status.0.load_balancer.0.ingress.0.ip
}

output "cluster_authentication" {
    value = "gcloud container clusters get-credentials ${google_container_cluster.waApi.name} --zone ${var.zone}"
}
