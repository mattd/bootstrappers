#!/bin/bash

UBUNTU_VERSION="karmic"
CONFIG_URI="http://www.thenestedfloat.com/build-tools"
USER_FILE="users.txt"
SSHD_CONFIG="sshd_config"
SSH_USER_RULE="AllowUsers"

set -e -x

# apt preparation and upgrade
apt-get update
apt-get -y upgrade

# user setup
curl $CONFIG_URI/$SSHD_CONFIG > /etc/ssh/sshd_config
curl $CONFIG_URI/$USER_FILE > /tmp/users
apt-get -y install makepasswd
addgroup wheel
while read user groups key_file; do
	useradd -U -G $groups -p `makepasswd --char=10` -s /bin/bash -m -d /home/$user $user
	mkdir /home/$user/.ssh
	chown $user:$user /home/$user/.ssh && chmod 700 /home/$user/.ssh
	curl $key_file > /home/$user/.ssh/authorized_keys
	chown $user:$user /home/$user/.ssh/authorized_keys && chmod 600 /home/$user/.ssh/authorized_keys
	SSH_USER_RULE="$SSH_USER_RULE $user"
done < /tmp/users
echo $SSH_USER_RULE >> /etc/ssh/sshd_config
/etc/init.d/ssh restart
rm /tmp/users

# the firewall
apt-get -y install ufw
yes | ufw enable
ufw logging on
ufw allow 80/tcp
ufw allow 4000/tcp
ufw allow 4001/tcp
ufw allow 22
ufw default deny

# locale
locale-gen en_US.UTF-8
/usr/sbin/update-locale LANG=en_US.UTF-8
