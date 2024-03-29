#!/bin/bash
#
# Copyright (c) Meta Platforms, Inc. and affiliates.

# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

# WhatsApp Business API GCP Template Version 1.0.0
sleep 35s

mkdir -p /etc/mysql/conf.d
cp /var/mysql/init/my.cnf /etc/mysql/my.cnf

sleep 1
mysql -uroot -p"$WA_DB_PASSWORD" -e "CREATE USER $WA_DB_USERNAME@'%' IDENTIFIED BY '$WA_DB_PASSWORD';"
mysql -uroot -p"$WA_DB_PASSWORD" -e "GRANT ALL PRIVILEGES ON *.* TO '$WA_DB_USERNAME'@'%' IDENTIFIED BY '$WA_DB_PASSWORD';"
mysql -uroot -p"$WA_DB_PASSWORD" -e "FLUSH PRIVILEGES;"

sleep 3s
