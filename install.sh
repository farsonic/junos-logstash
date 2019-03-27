#!/usr/bin/env bash

printf "JUNOS_SRX ELK Install script v0.1 27/01/2018"

#Confirm if user is either root or sudo root
if [[ $EUID -ne 0 ]]; then
   echo "/nThis script must be run as root" 
   exit 1
fi

cd /var/tmp/

#Determine the latest version of ELK based on current Elasticsearch version. All other components should match this release
#version=$(curl -s https://www.elastic.co/downloads/elasticsearch | grep Version: -A1 | grep -v Version | sed 's/<[^>]*>//g' | sed 's/ //g')
version="6.7.0"

start=$(date +%s.%N)
route=$(ip route get 8.8.8.8)
ip_address=$(awk '{print $7}' <<< "${route}")


#Install Prerequisites, Elasticsearch, JAVA and Git
#Assuming Python, Pip etc is already installed 
sudo apt update 
sudo apt install openjdk-8-jdk git python-pip
pip install --upgrade pip==9.0.3
wget -c https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-$version.deb
sudo dpkg -i elasticsearch-$version.deb
git clone https://github.com/Gallore/yaml_cli
cd yaml_cli
pip install .
cd /var/tmp/
printf "Modifying Elasticsearch YML file to local IP address....."
yaml_cli -f /etc/elasticsearch/elasticsearch.yml -s network.host $ip_address


#Install Kibana
wget -c https://artifacts.elastic.co/downloads/kibana/kibana-$version-amd64.deb
sudo dpkg -i kibana-$version-amd64.deb
printf "Modifying Kibana YML files to local IP address....."
sed -i.bak s/#server.host/server.host/ /etc/kibana/kibana.yml
sed -i.bak s/#elasticsearch.url/elasticsearch.url/ /etc/kibana/kibana.yml
yaml_cli -f /etc/kibana/kibana.yml -s server.host $ip_address
yaml_cli -f /etc/kibana/kibana.yml -s elasticsearch.url http://$ip_address:9200
sudo sysctl -w vm.max_map_count=262144


#Install LogStash
wget -c https://artifacts.elastic.co/downloads/logstash/logstash-$version.deb
sudo dpkg -i logstash-$version.deb
printf "Modifying Logstash YML file to local IP address....."
yaml_cli -f /etc/logstash/logstash.yml -s http.host $ip_address

#Install SRX specific components
cd /var/tmp/
rm -r junos-logstash/
git clone https://github.com/farsonic/junos-logstash.git
mkdir /etc/logstash/data/
wget -N http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz
wget -N http://geolite.maxmind.com/download/geoip/database/GeoLite2-ASN.tar.gz
tar -zxvf GeoLite2-City.tar.gz --transform='s/.*\///' -C /etc/logstash/data/
tar -zxvf GeoLite2-ASN.tar.gz --transform='s/.*\///' -C /etc/logstash/data/
cp /var/tmp/junos-logstash/configuration/* /etc/logstash/conf.d/
sed -i.bak s/IPADDRESS/$ip_address/ /etc/logstash/conf.d/20-output.conf

#Install curator
pip install elasticsearch-curator

printf "Lets start Elasticsearch....."
sudo systemctl daemon-reload
sudo systemctl enable elasticsearch.service
sudo systemctl start elasticsearch.service

printf "Lets start Kibana....."
sudo systemctl daemon-reload
sudo systemctl enable kibana.service
sudo systemctl start kibana.service

printf "Lets start Logstash....."
sudo systemctl daemon-reload
sudo systemctl enable logstash.service	
sudo systemctl start logstash.service


#Generate the required configuration snippet for SRX device to log to ELK
#Have this prompt the user for SRX IP Address and generate the needed configuration 
#set security log source-address 192.168.0.2
#set security log stream ELK format sd-syslog
#set security log stream ELK host 192.168.0.132
#set security log stream ELK host port 5140
