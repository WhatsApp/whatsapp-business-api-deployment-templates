#
# Copyright (c) Meta Platforms, Inc. and affiliates.

# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

# WhatsApp Business API Azure Template Version 1.0.0

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
  number_of_masterapp = 2
  # mysql_credential_vol        = "mysql-credential-vol"
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
  init_cmd                    = "export WA_DB_SSL_CA= && cd /opt/whatsapp/bin && ./launch_within_docker.sh"                                                     #DB in VM
  init_cmd_coreapp            = "export WA_DB_SSL_CA= && cd /opt/whatsapp/bin && IP=$(hostname -I) && export COREAPP_HOSTNAME=$IP && ./launch_within_docker.sh" #DB in VM
  # init_cmd         = "mkdir -p /opt/certs && echo \"Downloading CA bundle ...\" >> /var/log/whatsapp.log && cd /opt/certs && wget ${var.DBCertURL} -O ${var.DBConnCA} && ls -al ${var.DBConnCA} >> /var/log/whatsapp.log && cd /opt/whatsapp/bin && ./launch_within_docker.sh" # && while true; do sleep 30; done;" # && ./launch_within_docker.sh"
  # init_cmd_coreapp = "mkdir -p /opt/certs && echo \"Downloading CA bundle ...\" >> /var/log/whatsapp.log && cd /opt/certs && wget ${var.DBCertURL} -O ${var.DBConnCA} && ls -al ${var.DBConnCA} >> /var/log/whatsapp.log && cd /opt/whatsapp/bin && IP=$(hostname -I) && export COREAPP_HOSTNAME=$IP && ./launch_within_docker.sh"
}

resource "kubernetes_deployment" "webapp" {
  timeouts {
    create = "2m"
    update = "2m"
    delete = "1m"
  }
  metadata {
    name = "webapp"
    # namespace = kubernetes_namespace.deployment.metadata.0.name
    labels = {
      type = "webapp"
    }
  }
  spec {
    replicas = var.map_web_server_count[var.throughput]
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

        container {
          image = "docker.whatsapp.biz/web:${var.api-version}"
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
            claim_name = kubernetes_persistent_volume_claim.media-share.metadata.0.name
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
  depends_on = [azurerm_kubernetes_cluster_node_pool.webapp]
}

resource "kubernetes_deployment" "coreapp" {
  timeouts {
    create = "10m"
    update = "3m"
    delete = "1m"
  }
  metadata {
    name = "coreapp"
    # namespace = kubernetes_namespace.deployment.metadata.0.name
    labels = {
      type = "coreapp"
    }
  }

  spec {
    replicas = var.map_shards_count[var.throughput] + 1 // one more for disconnected HA coreapp
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

        volume {
          name = local.media_vol
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.media-share.metadata.0.name
          }
        }

        container {
          image = "docker.whatsapp.biz/coreapp:${var.api-version}"
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

  depends_on = [azurerm_kubernetes_cluster_node_pool.coreapp]

}

resource "kubernetes_deployment" "masterapp" {
  timeouts {
    create = "1m"
    update = "2m"
    delete = "1m"
  }
  metadata {
    name = "masterapp"
    # namespace = kubernetes_namespace.deployment.metadata.0.name
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

        container {
          image = "docker.whatsapp.biz/coreapp:${var.api-version}"
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
  depends_on = [azurerm_kubernetes_cluster_node_pool.coreapp]
}

resource "kubernetes_deployment" "monitor" {
  timeouts {
    create = "2m"
    update = "1m"
    delete = "1m"
  }
  metadata {
    name = "monitor"
    # namespace = kubernetes_namespace.deployment.metadata.0.name
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
          host_path {
            path = local.prom-vol-src
          }
        }

        volume {
          name = local.grafana-vol
          host_path {
            path = local.grafana-vol-src
          }
        }

        container {
          image = "prom/mysqld-exporter:v0.10.0"
          name  = "mysqld-exporter"

          resources {
            requests = {
              memory = "1Gi"
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
          image = "docker.whatsapp.biz/prometheus:${var.api-version}"
          name  = "prometheus"

          # command = ["/bin/sh", "-c", "while true; do sleep 30; done;"]

          security_context {
            run_as_user = 0
          }

          volume_mount {
            name       = local.prom-vol
            mount_path = local.prom-vol-container-path
          }

          resources {
            requests = {
              memory = "1Gi"
            }
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.mon-prom.metadata.0.name
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
          image = "docker.whatsapp.biz/grafana:${var.api-version}"
          name  = "grafana"

          volume_mount {
            name       = local.grafana-vol
            mount_path = local.grafana-vol-container-path
          }

          resources {
            requests = {
              memory = "1Gi"
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

  depends_on = [
    kubernetes_deployment.coreapp,
    kubernetes_deployment.masterapp,
    kubernetes_deployment.webapp
  ]
}

resource "kubernetes_daemonset" "exporter" {
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

resource "kubernetes_stateful_set" "db" {
  timeouts {
    create = "5m"
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

    service_name = kubernetes_service.db.metadata.0.name
    template {
      metadata {
        labels = {
          type = "db"
        }

        annotations = {}
      }

      spec {
        container {
          name              = "db-server"
          image             = "mysql:5.7.35"
          image_pull_policy = "IfNotPresent"

          # command = ["/bin/sh", "-c", "while true; do sleep 300; done;"]

          lifecycle {
            post_start {
              exec {
                command = ["/bin/bash", "-c", "/var/mysql/init/copy-cnf.sh"]
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

          # volume_mount {
          #   name       = local.mysql_credential_vol
          #   mount_path = local.mysql_credential_mount_path
          # }
        }

        termination_grace_period_seconds = 300

        volume {
          name = local.db_vol
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.db.metadata.0.name
          }
        }

        volume {
          name = local.mysql_init_vol
          config_map {
            name         = kubernetes_config_map.mysql-init.metadata.0.name
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

        # volume {
        #   name = local.mysql_credential_vol
        #   secret {
        #     secret_name = kubernetes_secret.env.metadata.0.name
        #   }
        # }
      }
    }

    update_strategy {
      type = "RollingUpdate"

      rolling_update {
        partition = 1
      }
    }
  }
}
