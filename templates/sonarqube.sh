#!/bin/bash
sudo yum upgrade -y
yum update -y
yum install java-1.8.0 -y
sudo wget -O /etc/yum.repos.d/sonar.repo http://downloads.sourceforge.net/project/sonar-pkg/rpm/sonar.repo
yum install sonar -y
service sonar start
# install postgesql server 
sudo adduser postgres
sudo amazon-linux-extras install postgresql13 -y
sudo yum install postgres-server postgres-devel postgresql -y
sudo /usr/bin/postgresql-setup --initdb 
sudo systemctl start postgresql
tail -1 /etc/passwd
amazon-linux-extras install java-openjdk11 -y
# edit tthe /opt/sonar/conf/sonar.properties
# sonar.jdbc.username=sonar
# sonar.jdbc.password=sonar
# sonar.jdbc.url=jdbc:postgresql://localhost/sonar
sudo mkdir /var/sonarqube
chown -R sonar:sonar /var/sonarqube/
# sonar.jdbc.data=/var/sonarqube/data
# sonar.jdbc.temp=/var/sonarqube/temp

# edit the vi /etc/sysctl.conf 
# vm.max_map_count=524288
# fs.file-max=131072
# set the limit 
# sonar hard nofile 65535
# sonar soft nofile 65535
