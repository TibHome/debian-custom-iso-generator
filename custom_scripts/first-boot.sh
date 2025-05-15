#!/bin/bash

# Prelogin message
cat <<EOF > /etc/issue
****************************************************************************
Debian GNU/Linux 12 customize
****************************************************************************

Welcome to your Custom Debian Environment.
This system is running a tailored configuration.

****************************************************************************

EOF

# Postlogin message
cat <<EOF > /etc/motd
*************************************
Welcome ${USER}
*************************************

Hostname       : $(hostname)
OS             : $(lsb_release -ds)

Have a great session !

EOF

echo "debian-custom" > /etc/hostname

setupcon

# Supprime le service après exécution
systemctl disable firstboot.service
rm -f /etc/systemd/system/firstboot.service
rm -f /usr/local/bin/*