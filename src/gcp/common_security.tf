#
# Copyright (c) Meta Platforms, Inc. and affiliates.

# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

# WhatsApp Business API GCP Template Version 1.0.0

# General Configuration

resource "kubernetes_pod_security_policy_v1beta1" "common_security_policy" {
  metadata {
    name = "common-security-policy"
  }

  spec {
    privileged                 = false
    allow_privilege_escalation = false

    volumes = [
      "*"
    ]

    run_as_user {
      rule = "MustRunAs"
      range {
        min = var.user_id
        max = var.user_id
      }
    }

    se_linux {
      rule = "RunAsAny"
    }

    run_as_group {
       rule = "MustRunAs"
      range {
        min = var.group_id
        max = var.group_id
      }
    }

    supplemental_groups {
      rule = "MustRunAs"
      range {
        min = var.supp_group_min
        max = var.supp_group_max
      }
    }

    fs_group {
      rule = "MustRunAs"
      range {
        min = var.user_id
        max = var.user_id
      }
    }
    read_only_root_filesystem = true
  }
}