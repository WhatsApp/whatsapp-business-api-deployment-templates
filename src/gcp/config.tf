#
# Copyright (c) Meta Platforms, Inc. and affiliates.

# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

# WhatsApp Business API GCP Template Version 1.0.0
#===================================
# Default Configurations - No need to adjust

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
    250 = 3
    300 = 3
  }
}

variable "map_shards_count" {
  type = map(number)
  default = {
    10  = 2
    20  = 4
    40  = 4
    80  = 8
    120 = 16
    160 = 16
    200 = 32
    250 = 32
    300 = 32
  }
}

# GCP compute instance configuration
variable "map_coreapp_class" {
  default = {
    "text_or_audio_or_video_or_doc" = {
      10  = "n2-standard-2"
      20  = "n2-standard-2"
      40  = "n2-standard-2"
      80  = "n2-standard-2"
      120 = "n2-standard-2"
      160 = "n2-standard-2"
      200 = "n2-standard-2"
      250 = "n2-standard-2"
      300 = "n2-standard-2"
    },
    "image1MB" = {
      10  = "n2-highcpu-8"
      20  = "n2-highcpu-8"
      40  = "n2-highcpu-8"
      80  = "n2-highcpu-8"
      120 = "n2-highcpu-8"
      160 = "n2-highcpu-8"
      200 = "n2-standard-8"
      250 = "n2-standard-16"
      300 = "n2-standard-16"
    },
    "image2MB_or_image4MB" = {
      10  = "n2-highcpu-8"
      20  = "n2-highcpu-8"
      40  = "n2-highcpu-8"
      80  = "n2-highcpu-8"
      120 = "n2-standard-8"
      160 = "n2-standard-8"
      200 = "n2-standard-8"
      250 = "n2-standard-16"
      300 = "n2-standard-16"
    }

  }
}

variable "map_db_class" {
  type = map(string)
  default = {
    10  = "n2-highmem-4"
    20  = "n2-highmem-8"
    40  = "n2-highmem-8"
    80  = "n2-highmem-8"
    120 = "n2-highmem-8"
    160 = "n2-highmem-8"
    200 = "n2-highmem-16"
    250 = "n2-highmem-32"
    300 = "n2-highmem-32"
  }
}

#GCP NFS-pvc sepecific config
variable "nfs-pvc-creation-complete" {
  type = bool
  default = true
}
