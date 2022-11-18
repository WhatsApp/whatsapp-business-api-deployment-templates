#!/bin/bash
#
# Copyright (c) Meta Platforms, Inc. and affiliates.

# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

# WhatsApp Business API Azure Template Version 1.0.0

sleep 5s

mkdir -p /etc/mysql/conf.d
cp /var/mysql/init/my.cnf /etc/mysql/my.cnf
