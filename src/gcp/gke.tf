#
# Copyright (c) Meta Platforms, Inc. and affiliates.

# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

# WhatsApp Business API GCP Template Version 1.0.0
provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

data "google_client_config" "default" {
}

provider "kubernetes" {
  config_path            = "~/.kube/config"
  host                   = "https://${google_container_cluster.waApi.endpoint}"

  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.waApi.master_auth.0.cluster_ca_certificate)
}

resource "google_container_cluster" "waApi" {
  name                =  "${var.project_id}-${var.name-prefix}-gke"
  location            = var.zone

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 3
}

resource "google_container_node_pool" "coreapp" {
  name       = "coreapp-node-pool"
  location   = var.zone
  cluster    = google_container_cluster.waApi.name
  node_count = var.map_shards_count[var.throughput] + 2

  node_config {
    preemptible  = false
    machine_type = var.map_coreapp_class[var.message_type][var.throughput]

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    labels = {
      type = "coreapp"
    }

    tags = [var.owner]

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

resource "google_container_node_pool" "webapp" {
  name       = "webapp-node-pool"
  location   = var.zone
  cluster    = google_container_cluster.waApi.name
  node_count = var.map_web_server_count[var.throughput] + 1

  node_config {
    preemptible  = false
    machine_type = var.map_coreapp_class[var.message_type][var.throughput]
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    labels = {
      type = "webapp"
    }
    tags = [var.owner]

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}
