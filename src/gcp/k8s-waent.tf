#
# Copyright (c) Meta Platforms, Inc. and affiliates.

# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

# WhatsApp Business API GCP Template Version 1.0.0


locals {
  root-vol                  = "root-vol"
  root-vol-src              = "/"
  root-vol-container-path   = "/rootfs"
  tmpfs-vol                 = "tmpfs"
  tmpfs-vol-src             = "/var/run"
  tmpfs-vol-container-path  = "/var/run"
  sys-vol                   = "sys-vol"
  sys-vol-src               = "/sys"
  sys-vol-container-path    = "/host/sys"
  docker-vol                = "docker-vol"
  docker-vol-src            = "/var/lib/docker"
  docker-vol-container-path = "/var/lib/docker"
  device-vol                = "device-vol"
  device-vol-src            = "/dev/disk"
  device-vol-container-path = "/dev/disk"
  proc-vol                  = "proc-vol"
  proc-vol-src              = "/proc"
  proc-vol-container-path   = "/host/proc"
}

locals {
  prom-vol                   = "prom-vol"
  prom-vol-src               = "/prometheus-data"
  prom-vol-container-path    = "/prometheus-data"
  grafana-vol                = "grafana-vol"
  grafana-vol-src            = "/var/lib/grafana"
  grafana-vol-container-path = "/var/lib/grafana"
}


locals {
  number_of_masterapp = 0
  mysql_credential_mount_path = "/var/mysql/credential"
  mysql_init_vol              = "mysql-init-vol"
  mysql_init_mount_path       = "/var/mysql/init"
  db_vol                      = "db-vol"
  db_mount_path               = "/var/lib/mysql"
  db_sub_path                 = "mysql"
  db_config_mount_path        = "/etc/mysql"
  db_config_sub_path          = "etc/mysql"
  media_mount_path            = "/usr/local/wamedia"
  media_vol                   = "media-vol"
  media_sub_path              = "waent/media"
  data_mount_path             = "/usr/local/waent/data"
  data_sub_path               = "waent/data"
  config_map_ref_name         = "config-env"
  config_map_ref_name_master  = "config-master"
  secret_map_ref_name         = "secret-env"
  init_cmd                    = "export WA_DB_SSL_CA= && export WA_WEB_JWT_CRYPTO_KEY='V2hhdDVBcHBFbnRlcnByaTUzQzFpZW50SE1BQ1NlY3IzdAo=' && cd /opt/whatsapp/bin && ./launch_within_docker.sh"                                                     #DB in VM
  init_cmd_coreapp            = "export WA_DB_SSL_CA= && cd /opt/whatsapp/bin && IP=$(hostname -I) && export COREAPP_HOSTNAME=$IP && ./launch_within_docker.sh" #DB in VM
}

resource "kubernetes_deployment" "webapp" {
  count = var.nfs-pvc-creation-complete ? 1 : 0

  timeouts {
    create = "5m"
    update = "2m"
    delete = "1m"
  }
  metadata {
    name = "webapp"
    labels = {
      type = "webapp"
    }
  }
  spec {
    replicas = 1
#    var.map_web_server_count[var.throughput]
    selector {
      match_labels = {
        type = "webapp"
      }
    }

    template {
      metadata {
        name   = "webapp"
        labels = { type = "webapp" }
      }
      spec {
        affinity {
          pod_anti_affinity {
            required_during_scheduling_ignored_during_execution {
              label_selector {
                match_expressions {
                  key      = "type"
                  operator = "In"
                  values   = ["webapp"]
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
                  values   = ["webapp"]
                }
              }
            }
          }
        }

        security_context {
          run_as_group    = var.group_id
          run_as_non_root = var.run_as_non_root
          run_as_user     = var.user_id
          fs_group        = var.group_id
        }

        container {
          name  = "webapp"

          command = ["/bin/sh", "-c"]

          args = [
            local.init_cmd
          ]

          volume_mount {
            name       = local.media_vol
            mount_path = local.media_mount_path
            sub_path   = local.media_sub_path
          }

          volume_mount {
            name       = local.media_vol
            mount_path = local.data_mount_path
            sub_path   = local.data_sub_path
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.env.metadata.0.name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.env.metadata.0.name
            }
          }

          port {
            container_port = 443
          }
        }

        volume {
          name = local.media_vol
          persistent_volume_claim {
            # manifest embedded yaml will also fail
            # claim_name = "nfs-pvc-test"

            #only raw yaml works
            claim_name = "nfs-pvc"
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
  depends_on = [google_container_node_pool.webapp, kubernetes_service.nfs_server]
}

resource "kubernetes_deployment" "coreapp" {
  count = var.nfs-pvc-creation-complete ? 1 : 0

  timeouts {
    create = "10m"
    update = "5m"
    delete = "1m"
  }
  metadata {
    name = "coreapp"
    labels = {
      type = "coreapp"
    }
  }

  spec {
    replicas = 1
#    var.map_shards_count[var.throughput] + 1 // one more for disconnected HA coreapp
    selector {
      match_labels = {
        type = "coreapp"
      }
    }

    template {
      metadata {
        name   = "coreapp"
        labels = { type = "coreapp" }
      }

      spec {
        affinity {
          pod_anti_affinity {
            required_during_scheduling_ignored_during_execution {
              label_selector {
                match_expressions {
                  key      = "type"
                  operator = "In"
                  values   = ["coreapp"]
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
                  values   = ["coreapp"]
                }
              }
            }
          }
        }

        security_context {
          run_as_group    = var.group_id
          run_as_non_root = var.run_as_non_root
          run_as_user     = var.user_id
          fs_group        = var.group_id
        }

        volume {
          name = local.media_vol
          persistent_volume_claim {
            # manifest embedded yaml will fail
            # claim_name = "nfs-pvc-test"

            #raw yaml works
            claim_name = "nfs-pvc"
          }
        }

        container {
          name  = "coreapp"

          command = ["/bin/sh", "-c"]

          args = [
            local.init_cmd_coreapp
          ]

          volume_mount {
            name       = local.media_vol
            mount_path = local.media_mount_path
            sub_path   = local.media_sub_path
          }

          volume_mount {
            name       = local.media_vol
            mount_path = local.data_mount_path
            sub_path   = local.data_sub_path
          }

          env_from {
            config_map_ref {
              name = local.config_map_ref_name
            }
          }

          env_from {
            secret_ref {
              name = local.secret_map_ref_name
            }
          }

          port {
            container_port = 6250
          }
          port {
            container_port = 6251
          }
          port {
            container_port = 6252
          }
          port {
            container_port = 6253
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

  depends_on = [google_container_node_pool.coreapp, kubernetes_service.nfs_server]
}

resource "kubernetes_deployment" "masterapp" {
  count = var.nfs-pvc-creation-complete ? 1 : 0

  timeouts {
    create = "5m"
    update = "2m"
    delete = "1m"
  }
  metadata {
    name = "masterapp"
    labels = {
      type = "masterapp"
    }
  }

  spec {
    replicas = local.number_of_masterapp
    selector {
      match_labels = {
        type = "masterapp"
      }
    }

    template {
      metadata {
        name   = "masterapp"
        labels = { type = "masterapp" }
      }

      spec {
        affinity {
          pod_anti_affinity {
            required_during_scheduling_ignored_during_execution {
              label_selector {
                match_expressions {
                  key      = "type"
                  operator = "In"
                  values   = ["masterapp"]
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
                  values   = ["webapp"]
                }
              }
            }
          }
        }

        security_context {
          run_as_group    = var.group_id
          run_as_non_root = var.run_as_non_root
          run_as_user     = var.user_id
          fs_group        = var.group_id
        }

        container {
          name  = "masterapp"

          command = ["/bin/sh", "-c"]

          args = [
            local.init_cmd_coreapp
          ]

          env_from {
            config_map_ref {
              name = local.config_map_ref_name
            }
          }

          env_from {
            config_map_ref {
              name = local.config_map_ref_name_master
            }
          }

          env_from {
            secret_ref {
              name = local.secret_map_ref_name
            }
          }

          port {
            container_port = 6250
          }
          port {
            container_port = 6251
          }
          port {
            container_port = 6252
          }
          port {
            container_port = 6253
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
  depends_on = [google_container_node_pool.coreapp]
}


resource "kubernetes_service" "webapp" {
  count = var.nfs-pvc-creation-complete ? 1 : 0

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

    port {
      port        = 443
      target_port = 443
    }

    type = "LoadBalancer"
  }
  depends_on = [kubernetes_deployment.webapp]
}
