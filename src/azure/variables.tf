#
# Copyright (c) Meta Platforms, Inc. and affiliates.

# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

# WhatsApp Business API Azure Template Version 1.0.0

variable "name-prefix" {
  default = "wabiz"
}

variable "location" {
  default = "eastasia"
}

variable "owner" {
  default = "meta"
}

variable "dbusername" {
  default = "dbadmin"
}

variable "dbpassword" {
  default = "Meta888"
}

variable "ssh-pub-key" {
  default = "~/.ssh/azure-aks.pub"
}

variable "DBCertURL" {
  default = "" # mysql in vm
  # default = "https://dl.cacerts.digicert.com/DigiCertGlobalRootCA.crt.pem" # flexible server
  # default = "https://www.digicert.com/CACerts/BaltimoreCyberTrustRoot.crt.pem" # single server
}

variable "DBConnCA" {
  default = "/opt/certs/db-ca.pem"
}

variable "namespace" {
  default = "default"
  # default = "${var.name-prefix}-${var.owner}"
}

variable "api-version" {
  default = "v2.41.2"
}

variable "wabiz-web-username" {
  default = "admin"
}

variable "wabiz-web-password" {
  default = "1234Qwer..."
}

variable "mon-web-username" {
  default = "admin"
}

variable "mon-smtp-username" {
  default = "admin"
}

variable "mon-web-password" {
  default = "meta@meta!@#.com"
}

variable "mon-smtp-password" {
  default = "meta@meta!@#.com"
}

variable "db-iops" {
  default = 1000
}

variable "k8s-vm-class" {
  default = "Standard_D2s_v4"
}

# at least 2 for multi-connect required
variable "map_web_server_count" {
  type = map(number)
  default = {
    10  = 2
    20  = 2
    40  = 2
    60  = 2
    80  = 2
    100 = 2
    120 = 2
    160 = 2
    200 = 2
  }
}

variable "throughput" {
  default = 200
}

variable "map_shards_count" {
  type = map(number)
  default = {
    10  = 2
    20  = 4
    40  = 8
    80  = 16
    120 = 32
    160 = 32
    200 = 32
  }
}

variable "map_db_class" {
  type = map(string)
  default = {
    10  = "Standard_E2as_v4"
    20  = "Standard_E2as_v4"
    40  = "Standard_E4as_v4"
    80  = "Standard_E4as_v4"
    120 = "Standard_E8as_v4"
    160 = "Standard_E8as_v4"
    200 = "Standard_E16as_v4"
  }
}
variable "map_db_iops" {
  type = map(string)
  default = {
    10  = 800
    20  = 1500
    40  = 2500
    80  = 3500
    120 = 4000
    160 = 4500
    200 = 6000
  }
}

variable "map_db_throughput" {
  type = map(string)
  default = {
    10  = 20
    20  = 40
    40  = 60
    80  = 80
    120 = 100
    160 = 150
    200 = 180
  }
}

/* do NOT uncomment below code

variable "map_db_buffer_pool_size" {
  type = map(string)
  default = {
    10  = 1024 * 1024 * 1024 * 16 * 0.75
    20  = 1024 * 1024 * 1024 * 16 * 0.75
    40  = 1024 * 1024 * 1024 * 32 * 0.75
    80  = 1024 * 1024 * 1024 * 32 * 0.75
    120 = 1024 * 1024 * 1024 * 64 * 0.75
    160 = 1024 * 1024 * 1024 * 64 * 0.75
    200 = 1024 * 1024 * 1024 * 256 * 0.75
    250 = 1024 * 1024 * 1024 * 256 * 0.75
    300 = 1024 * 1024 * 1024 * 256 * 0.75
  }
}

variable "map_db_buffer_pool_instances" {
  type = map(string)
  default = {
    10  = 2
    20  = 2
    40  = 4
    80  = 4
    120 = 8
    160 = 8
    200 = 32
    250 = 32
    300 = 32
  }
}

variable "map_db_query_cache_size" {
  type = map(string)
  default = {
    10  = 1024 * 1024 * 1024 * 2
    20  = 1024 * 1024 * 1024 * 2
    40  = 1024 * 1024 * 1024 * 4
    80  = 1024 * 1024 * 1024 * 4
    120 = 1024 * 1024 * 1024 * 8
    160 = 1024 * 1024 * 1024 * 8
    200 = 1024 * 1024 * 1024 * 32
    250 = 1024 * 1024 * 1024 * 32
    300 = 1024 * 1024 * 1024 * 32
  }
}


variable "map_db_size" {
  type = map(number)
  default = {
    10  = 1024 * 64 #64GB / 64 x 3 = 192 IOPS
    20  = 1024 * 128
    30  = 1024 * 256
    40  = 1024 * 256
    60  = 1024 * 512
    80  = 1024 * 512
    100 = 1024 * 512
    120 = 1024 * 512
    160 = 1024 * 1024
    200 = 1024 * 1024
  }
}

variable "map_db_class" {
  type = map(string)
  default = {
    10  = "GP_Gen5_2"
    20  = "GP_Gen5_2"
    30  = "GP_Gen5_2"
    40  = "GP_Gen5_2"
    60  = "GP_Gen5_2"
    80  = "GP_Gen5_2"
    100 = "GP_Gen5_2"
    120 = "GP_Gen5_2"
    160 = "GP_Gen5_4"
    200 = "GP_Gen5_4"
  }
}


*/
