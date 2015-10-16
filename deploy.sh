#!/usr/bin/bash
shopt -s nocasematch
#Download and install PuppetLabs repo for EL7.
rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm
if [[ $1 = "server" ]]; then
  #open puppet port in firewalld
  firewall-cmd --zone=public --add-port=8140/tcp --permanent
  firewall-cmd --reload
  
  #install puppet, apache and other dependencies
  echo "installing puppet server"
  yum install puppet-server -y -q -e 0
  systemctl start puppetmaster.service
  puppet resource service puppetmaster ensure=running enable=true
  echo "Puppet is installed and running."
  echo "Adding phusionpassenger repo"
  curl --fail -sSLo /etc/yum.repos.d/passenger.repo https://oss-binaries.phusionpassenger.com/yum/definitions/el-passenger.repo
  echo "installing httpd, httpd-devel, mod-ssl, ruby-devel, rubygems, gcc-c++, curl-devel, zlib-devel, make, automake, openssl-devel, mod_passenger"
  yum install httpd httpd-devel mod_ssl ruby-devel rubygems gcc-c++ curl-devel zlib-devel make automake openssl-devel mod_massenger -y -q -e 0
  #install rack
  gem install rack
 
  #create virtual hostfile for puppet.
  touch /etc/httpd/conf.d/puppetmaster.conf 
  echo "puppetmaster.conf created. Configure the VirtualHost!"  
  echo "When done"
  echo <<EOF
Stop puppetmaster
/etc/init.d/puppetmaster stop
Start Apache
/etc/init.d/httpd start

Disable WEBrick
chkconfig puppetmaster off
chkconfig httpd on

Then configure puppet. And test apache config!

Move rack-cfg
from /usr/share/puppet/ext/rack/config.ru
to /usr/share/puppet/rack/puppetmasterd/
set owner
puppet:puppet /usr/share/puppet/rack/puppetmasterd/config.ru
EOF
 


fi

if [[ $1 = "client" ]]; then
  yum install puppet -y
fi
