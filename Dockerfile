FROM ubuntu:latest
MAINTAINER Dwi Ash <dwiasharialdy@gmail.com>

RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list
RUN apt-get update
RUN apt-get -y upgrade

# Keep upstart from complaining
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -s /bin/true /sbin/initctl

# Required packages
RUN apt-get -y install mysql-server mysql-client apache2 php5-mysql php-apc pwgen python-setuptools unzip php5-curl php5-gd php5-intl php-pear php5-imagick php5-imap php5-mcrypt php5-memcache php5-ming php5-ps php5-pspell php5-recode php5-snmp php5-sqlite php5-tidy php5-xmlrpc php5-xsl

# apache + php
RUN apt-get -y install php5

# mysql config
RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/my.cnf

# setup apache revised
RUN a2enmod rewrite
RUN rm /etc/apache2/sites-available/default
ADD ./apache.conf /etc/apache2/sites-available/default
RUN mkdir /app-log

# setup user for apache
RUN adduser --no-create-home --disabled-login --disabled-password arandomuser
RUN sed -i -e"s/www-data/arandomuser/" /etc/apache2/envvars
RUN echo "<?php phpinfo();" > /app-log/info.php

# setup supervisor 
RUN /usr/bin/easy_install supervisor
# please don't use cached version
ADD ./supervisord.conf /etc/supervisord.conf

# startup.sh
# please don't use cached version
ADD ./startup.sh /startup.sh
RUN chmod 755 /startup.sh

# private expose
EXPOSE 80

CMD ["/bin/bash", "/startup.sh"]
