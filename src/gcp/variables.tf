#
# Copyright (c) Meta Platforms, Inc. and affiliates.

# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

# WhatsApp Business API GCP Template Version 1.0.0

# General Configuration
variable "name-prefix" {
  default = ""
}

# Filling out before you start
variable "project_id" {
  default =  ""
  description = "project id"

  validation {
    condition     = length(var.project_id) > 0
    error_message = "Project ID cannot be empty."
  }
}

variable "region" {
  default = "us-west1"
  description = "region"
}

variable "zone" {
  default = "us-west1-a"
  description = "zone"
}

variable "owner" {
  default = "meta"
  description = "Owner"
}

# Throughput Configuration
variable "throughput" {
  type = number
  default = 300

  validation {
    condition     = contains([10, 20, 40, 60, 80, 100, 120,160,200,250,300], var.throughput)
    error_message = "Valid values var.throughput are: 10, 20, 40, 60, 80, 100, 120, 160, 200, 250, 300."
  }
}

variable "message_type" {
  type = string
  default = "image2MB_or_image4MB"

  validation {
    condition     = contains(["text_or_audio_or_video_or_doc", "image1MB", "image2MB_or_image4MB"], var.message_type)
    error_message = "Valid values for var.messageType are: text, audio, video, doc, image1MB, image2MB, image4MB."
  }
}

# WhatsApp Business API Configuration
variable "api-version" {
   default = "v2.45.2"
}

# Database Configuration
variable "dbusername" {
  default = "dbadmin"
}

variable "dbpassword" {
  type = string
  description = "Database admin user password"
  validation {
    condition     = length(var.dbpassword) > 0
    error_message = "Database admin user password cannot be empty. Should NOT contain any of these characters: ?{}&~!()^="
  }
  default = ""
}

variable "DBCertURL" {
  default = "" # mysql in vm
  # default = "https://dl.cacerts.digicert.com/DigiCertGlobalRootCA.crt.pem" # flexible server
  # default = "https://www.digicert.com/CACerts/BaltimoreCyberTrustRoot.crt.pem" # single server
}

variable "DBConnCA" {
  default = "/opt/certs/db-ca.pem"
}

# Grafana Configuration
variable "mon-web-username" {
  default = "admin"
}

#Login in password
variable "mon-web-password" {
  default = ""
  description = "Set the Grafana dashboard login password"
  validation {
    condition     = length(var.mon-web-password) > 0
    error_message = "Grafana admin user password cannot be empty."
  }
}

variable "mon-smtp-enabled" {
  default = "0"
}

variable "mon-smtp-host" {
  default = ""
}

variable "mon-smtp-username" {
  default = "admin"
}

variable "mon-smtp-password" {
  default = ""
}

#!!!!!Need to match Postman API user and password!!!
variable "wabiz-web-username" {
  default = "admin"
}

variable "wabiz-web-password" {
  type = string
  description = "WhatsApp Business API Password"
  validation {
    condition     = length(var.wabiz-web-password) >= 8 && length(var.wabiz-web-password) <= 64
    error_message = "Password needs to be 8-64 characters long with at least 1 digit, 1 uppercase letter, 1 lowercase letter and 1 special character"
  }
  default = ""
}
