#!/bin/bash

UBUNTU_CODENAME="lucid"
SERVER_FQDN="https://api.opscode.com/organizations/bytexbyte"

set -e -x

# enable repo for java installation
echo "deb http://archive.canonical.com/ $UBUNTU_CODENAME partner" >> /etc/apt/sources.list

# update apt and upgrade
apt-get update
apt-get -y upgrade

# set locale
locale-gen en_US.UTF-8
/usr/sbin/update-locale LANG=en_US.UTF-8

# install chef prereqs
apt-get -y install ruby ruby1.8-dev libopenssl-ruby1.8 libshadow-ruby1.8 irb build-essential wget ssl-cert

# install rubygems from source
cd /tmp
wget http://rubyforge.org/frs/download.php/69365/rubygems-1.3.6.tgz
tar zxf rubygems-1.3.6.tgz
cd rubygems-1.3.6
sudo ruby setup.rb
sudo ln -sfv /usr/bin/gem1.8 /usr/bin/gem

# install chef, chef-server, and ohai
gem sources -a http://gems.opscode.com
gem install ohai chef --no-rdoc --no-ri

echo "file_cache_path '/tmp/chef-solo'
cookbook_path '/tmp/chef-solo/cookbooks'
recipe_url 'http://s3.amazonaws.com/chef-solo/bootstrap-latest.tar.gz'" >> ~/solo.rb

echo "{
	\"bootstrap\": {
		\"chef\": {
		\"url_type\": \"http\",
		\"init_style\": \"runit\",
		\"path\": \"/srv/chef\",
		\"serve_path\": \"/srv/chef\",
		\"server_fqdn\": \"$SERVER_FQDN\"
		}
	},
	\"run_list\": [ \"recipe[bootstrap::client]\" ]
}" >> ~/chef.json

chef-solo -c ~/solo.rb -j ~/chef.json
