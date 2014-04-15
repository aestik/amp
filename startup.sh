#!/bin/bash

#mysql has to be started this way as it doesn't work to call from /etc/init.d
/usr/bin/mysqld_safe &
sleep 10s

# Here we generate random passwords (thank you pwgen!).
# The first two are for mysql users, the last batch for random keys in wp-config.php
WORDPRESS_DB="wordpress"
MYSQL_PASSWORD="mysqlhehehe"
WORDPRESS_PASSWORD="mysqlhehehe"

# Assign new password for root
mysqladmin -u root password $MYSQL_PASSWORD

# Create new database for WordPress
mysql -uroot -p$MYSQL_PASSWORD -e "CREATE DATABASE wordpress;"

#This is so the passwords show up in logs.
echo mysql root password: $MYSQL_PASSWORD
echo wordpress password: $WORDPRESS_PASSWORD
echo $MYSQL_PASSWORD > /mysql-root-pw.txt
echo $WORDPRESS_PASSWORD > /wordpress-db-pw.txt

sed -e "s/database_name_here/$WORDPRESS_DB/
s/username_here/root/
s/password_here/$MYSQL_PASSWORD/
/'AUTH_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'SECURE_AUTH_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'LOGGED_IN_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'NONCE_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'AUTH_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'SECURE_AUTH_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'LOGGED_IN_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'NONCE_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/" /app/www/wp-config-sample.php > /app/www/wp-config.php


chown -hR 1000:1000 /app/www/wp-config.php


# cek apakah sudah ada file .sql di folder /app/db/db.sql
if [ -f /app/db/wordpress.sql ]
then

	# Upload database
	mysql -u root -p$WORDPRESS_PASSWORD wordpress < /app/db/wordpress.sql

	OLD=$(echo "SELECT option_value from wp_options WHERE option_name='siteurl'" | mysql -s -r -u root -pmysqlhehehe wordpress)
	OLD=$(echo $OLD | sed -e "s/http://g")

	NEW=$(hostname -f)
	NEW=//$NEW
	echo "change" $OLD
	echo "with" $NEW

	/usr/bin/php /opt/Search-Replace-DB-master/srdb.cli.php -h localhost -n wordpress -u root -p mysqlhehehe -s "$OLD" -r "$NEW"

fi


# kill mysql daemon, so it can be started by supervisord
killall mysqld


# start all the services
/usr/local/bin/supervisord -n


# backup database
/usr/bin/mysqld_safe &
sleep 10s
mysqldump -u root -p$MYSQL_PASSWORD wordpress > /app/db/wordpress.sql
killall mysqld


# change files ownership
chown -hR 1000:1000 /app/db/
