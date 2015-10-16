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
  yum install epel-release -y -q -e 1
  yum install httpd httpd-devel mod_ssl ruby-devel rubygems gcc-c++ curl-devel zlib-devel make automake openssl-devel mod_passenger -y -q -e 0
 
  #create virtual hostfile for puppet.
  #touch /etc/httpd/conf.d/puppetmaster.conf 
  sed -i -- "s/<CERT>/$HOSTNAME/g" puppetmaster.conf
  cp puppetmaster.conf /etc/httpd/conf.d/puppetmaster.conf
  echo "puppetmaster.conf moved to /etc/httpd/conf.d/puppetmaster.conf"  
  service puppetmaster stop
  service httpd start
  chkconfig puppetmaster off
  chkconfig  httpd on 
  #Move rack config.
  mkdir -p /usr/share/puppet/rack/puppetmasterd
  mkdir /usr/share/puppet/rack/puppetmasterd/public /usr/share/puppet/rack/puppetmasterd/tmp
  cp /usr/share/puppet/ext/rack/config.ru /usr/share/puppet/rack/puppetmasterd/
  chown puppet:puppet /usr/share/puppet/rack/puppetmasterd/config.ru
  sed -i -- "s/\[master\]/\[master\]\ncertname = $HOSTNAME\nautosign = true\ndns_alt_names = puppet,$HOSTNAME\n/g" /etc/puppet/puppet.conf
  #Set SElinux in permissive mode. TODO: fix SElinux permissions.
  setenforce 0
fi

if [[ $1 = "client" ]]; then
  yum install puppet -y
  puppet resource service puppet ensure=running enable=true
  sed -i -- "s/\[agent\]/\[agent\]\nserver = puppet.lab.local\nreport = true\npluginsync = true\n/g" /etc/puppet/puppet.conf
  chkconfig puppet on
  puppet agent --daemonizei
  ##Set SELinux in permissive mode. TODO: FIX THIS!!!
  setenforce 0
fi
