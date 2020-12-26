#!/bin/bash

# update ubuntu
# sudo apt -y update
# echo n | sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# set ls directory color
sudo echo "export LS_COLORS+=':ow=0;33'" >> /home/vagrant/.bashrc

# set timezone
sudo unlink /etc/localtime
sudo ln -s /usr/share/zoneinfo/Europe/Zurich /etc/localtime
timedatectl

# create date string
# DATE=`date +%Y%m%d%H%M`

# set version
# UBUNTU_VERSION=$(lsb_release -a | grep Release | awk  '{print $2}')
# echo "ubuntu-$UBUNTU_VERSION" > /vagrant/version