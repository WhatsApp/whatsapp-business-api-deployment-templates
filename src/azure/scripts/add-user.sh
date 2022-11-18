#!/bin/bash
#
# Copyright (c) Meta Platforms, Inc. and affiliates.

# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

# WhatsApp Business API Azure Template Version 1.0.0

sleep 5s

mysql -uroot -p"$WA_DB_PASSWORD" -e "CREATE USER IF NOT EXISTS $WA_DB_USERNAME@'%' IDENTIFIED BY '$WA_DB_PASSWORD';"
mysql -uroot -p"$WA_DB_PASSWORD" -e "GRANT ALL PRIVILEGES ON *.* TO '$WA_DB_USERNAME'@'%' IDENTIFIED BY '$WA_DB_PASSWORD';"
mysql -uroot -p"$WA_DB_PASSWORD" -e "FLUSH PRIVILEGES;"
