#!/usr/bin/bash
#Download and install PuppetLabs repo for EL7.
rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm

if [ $1="server" ]; then
  firewall-cmd --zone=public --add-port=8140/tcp --permanent
  firewall-cmd --reload

fi

 
