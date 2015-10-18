#!/usr/bin/bash
if [ "$(id -u)" != 0 ]; then
  echo "Script must be executed as Root!" 1>&2
  exit 1
fi
#This is not a good solution.
echo "Setting SELinux in permissive mode."
setenforce 0
shopt -s nocasematch
#Download and install PuppetLabs repo for EL7.
rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm
if [[ $1 = "server" ]]; then
  echo "Starting installation!"
  #Adding extra repos.
  curl --fail -sSLo /etc/yum.repos.d/passenger.repo https://oss-binaries.phusionpassenger.com/yum/definitions/el-passenger.repo
  #install puppet, apache and other dependencies
  echo "Installing puppetmaster."
  yum install puppet-server -y -q -e 0
  echo "Done installing puppetmaster."
  echo "Starting puppetmaster.service"
  systemctl start puppetmaster.service
  puppet resource service puppetmaster ensure=running enable=true
  echo "Installing epel-release package."
  yum install epel-release -y -q -e 0
  echo "installing httpd, httpd-devel, mod-ssl, ruby-devel, rubygems, gcc-c++, curl-devel, zlib-devel, make, automake, openssl-devel, mod_passenger"
  yum install httpd httpd-devel mod_ssl ruby-devel rubygems gcc-c++ curl-devel zlib-devel make automake openssl-devel mod_passenger -y -q -e 0
  echo "Installation done. Starting configuration."
  #open puppet port in firewalld
  echo "Updating firewall rules"
  firewall-cmd --zone=public --add-port=8140/tcp --permanent
  firewall-cmd --reload
  echo "Done"
  #create virtual hostfile for puppet.
  echo "Editing and moving puppetmaster.conf"
  sed -i -- "s/<CERT>/$HOSTNAME/g" puppetmaster.conf
  cp puppetmaster.conf /etc/httpd/conf.d/puppetmaster.conf
  echo "puppetmaster.conf moved to /etc/httpd/conf.d/puppetmaster.conf"  
  echo "stopping puppetmaster service."
  service puppetmaster stop
  chkconfig puppetmaster off
  echo "Starting httpd service"
  service httpd start
  chkconfig  httpd on 
  echo "Creating directory: /usr/share/puppet/rack/puppetmasterd"
  mkdir -p /usr/share/puppet/rack/puppetmasterd
  echo "Creating directory: /usr/share/puppet/rack/puppetmasterd/public"
  echo "Creating directory: /usr/share/puppet/rack/puppetmasterd/tmp"
  mkdir /usr/share/puppet/rack/puppetmasterd/public /usr/share/puppet/rack/puppetmasterd/tmp
  echo "Moving /usr/share/puppet/ext/rack/config.ru to /usr/share/puppet/rack/puppetmasterd/"
  cp /usr/share/puppet/ext/rack/config.ru /usr/share/puppet/rack/puppetmasterd/
  echo "Updating ownership of config.ru to puppet:puppet"
  chown puppet:puppet /usr/share/puppet/rack/puppetmasterd/config.ru
  echo "Updating puppet.conf, adding certname, autosign and dns_alt_names options."
  sed -i -- "s/\[master\]/\[master\]\ncertname = $HOSTNAME\nautosign = true\ndns_alt_names = puppet,$HOSTNAME\n/g" /etc/puppet/puppet.conf
fi

if [[ $1 = "client" ]]; then
  yum install puppet -y
  puppet resource service puppet ensure=running enable=true
  sed -i -- "s/\[agent\]/\[agent\]\nserver = puppet.lab.local\nreport = true\npluginsync = true\n/g" /etc/puppet/puppet.conf
  chkconfig puppet on
  puppet agent --daemonize
fi
