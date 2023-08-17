#
# Copyright (c) Meta Platforms, Inc. and affiliates.

# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

# WhatsApp Business API GCP Template Version 1.0.0

resource "google_container_node_pool" "db" {
  name       = "db-node-pool"
  location   = var.zone
  cluster    = google_container_cluster.waApi.name
  node_count = 2

  node_config {
    preemptible  = false
    machine_type = var.map_db_class[var.throughput]

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    labels = {
      type = "db"
    }

    tags = [var.owner]

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}


resource "kubernetes_stateful_set" "db" {
  timeouts {
    create = "8m"
    update = "1m"
  }
  metadata {
    name = "db"
    labels = {
      type = "db"
    }
  }

  spec {
    pod_management_policy  = "Parallel"
    replicas               = 1
    revision_history_limit = 5

    selector {
      match_labels = {
        type = "db"
      }
    }

    service_name = "db"
    template {
      metadata {
        labels = {
          type = "db"
        }

        annotations = {}
      }

      spec {
        affinity {
          node_affinity {
            required_during_scheduling_ignored_during_execution {
              node_selector_term {
                match_expressions {
                  key      = "type"
                  operator = "In"
                  values   = ["db"]
                }
              }
            }
          }
        }

        container {
          name              = "db-server"
          image             = "mysql:8.0.34"                                                                                |            image             = ""
          image_pull_policy = "IfNotPresent"


          lifecycle {
            post_start {
              exec {
                command = ["/bin/bash", "-c", "/var/mysql/init/copy-cnf.sh"]
                #  command = ["/bin/bash", "-c", "/var/mysql/init/add-user.sh"]
              }
            }
          }

          port {
            container_port = 3306
          }

          env {
            name  = "MYSQL_ROOT_PASSWORD"
            value = var.dbpassword
          }

          env_from {
            secret_ref {
              name = local.secret_map_ref_name
            }
          }

          volume_mount {
            name       = local.db_vol
            mount_path = local.db_mount_path
            sub_path   = local.db_sub_path
          }

          volume_mount {
            name       = local.db_vol
            mount_path = local.db_config_mount_path
            sub_path   = local.db_config_sub_path
          }

          volume_mount {
            name       = local.mysql_init_vol
            mount_path = local.mysql_init_mount_path
          }

          volume_mount {
            name       = "mysql-initdb"
            mount_path = "/docker-entrypoint-initdb.d"
          }
        }

        termination_grace_period_seconds = 300

        volume {
          name = local.db_vol
          persistent_volume_claim {
            # claim_name = google_compute_disk.extreme-disk.name
            claim_name = kubernetes_persistent_volume_claim.db.metadata.0.name
          }
        }

        volume {
          name = local.mysql_init_vol
          config_map {
            name         = kubernetes_config_map.mysql-init.metadata[0].name
            default_mode = "0777"
          }
        }

        volume {
          name = "mysql-initdb"
          config_map {
            name         = kubernetes_config_map.mysql-initdb.metadata.0.name
            default_mode = "0777"
          }
        }
      }
    }

    update_strategy {
      type = "RollingUpdate"

      rolling_update {
        partition = 1
      }
    }
  }

  depends_on = [google_container_node_pool.db, kubernetes_persistent_volume_claim.db]
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
