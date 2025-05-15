#!/bin/bash

cat <<EOF > /etc/systemd/system/firstboot.service
[Unit]
Description=First boot script
DefaultDependencies=no
Before=getty@tty1.service
After=local-fs.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/first-boot.sh
RemainAfterExit=no

[Install]
WantedBy=multi-user.target
EOF
