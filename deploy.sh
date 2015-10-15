#!/usr/bin/bash
shopt -s nocasematch
#Download and install PuppetLabs repo for EL7.
rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm
if [[ $1 = "server" ]]; then
  #open puppet port in firewalld
  firewall-cmd --zone=public --add-port=8140/tcp --permanent
  firewall-cmd --reload
  
  #install puppet, apache and other dependencies
  yum install puppet-server -y -q -e 0
  yum install httpd \
	      httpd-devel \ 
	      mod_ssl \
	      ruby-devel \
	      rubygems \
	      gcc-c++ \
	      curl-devel \
	      zlib-devel \
	      make \
	      automake \
	      openssl-devel -y -q -e 0
  #install rack / Passenger
  gem install rack passenger
  #install passenger-module
  passenger-install-apache2-module --auto
  #start puppet master
  ##systemctl start puppetmaster.service
  #run puppet master on startup
  ##puppet resource service puppetmaster ensure=running enable=true
 
  #create virtual hostfile for puppet.
  ##touch /etc/httpd/conf.d/puppetmaster.conf 
  ##echo "puppetmaster.conf created. Configure the VirtualHost!"  
fi

if [[ $1 = "client" ]]; then
  yum install puppet -y
fi
