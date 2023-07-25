#!/bin/bash

#
# Change localhost name
#

echo "Current host name is: " $(hostname)
echo  "Would you like to set a new hostname? [y/n] "
read decision
if [[ "$decision" =~ ^[yY]$ ]];
then
    echo "What should be the new name of the host?"
    read new_hostname
    sudo hostname "$new_hostname"
fi

release=/etc/os-release
#to be done on Ubuntu and Arch
#if  grep -q "Ubuntu" $release || grep -q "Debian" $release
#then
#    sudo apt install -y apache2
#    sudo apt install -y libapache2-mod-php
#    sudo systemctl restart apache2
#    sudo apt install -y mysql-server
#fi

#if grep -q "Arch" $release
#then
#    yes | sudo pacman -S httpd
#    yes | sudo pacman -S php
#    sudo systemctl restart apache2
#    yes | sudo pacman -S mysql-server
#fi

#
# Installing LAMP with dnf
#

if grep -q "CentOS" $release || grep -q "Fedora" $release || grep -q "RedHat" $release
then
    sudo dnf install -y httpd
    systemctl start httpd
    systemctl enable httpd.service
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=https
    firewall-cmd --reload
    sudo dnf install -y mariadb-server mariadb
    systemctl start mariadb.service
    systemctl enable mariadb.service
    sudo dnf install -y php
    sudo systemctl restart httpd.service
    sudo dnf install -y php-mysqlnd php-curl
    sudo systemctl restart httpd.service
    sudo dnf install -y phpMyAdmin
else
    echo 'This script does not support your distribution of Linux'
    exit 1
fi

#
# Allow all connections to phpMyAdmin
#

echo "Do you want to allow connections to phpMyAdmin from every ip (not only localhost) [y/n]" 
read decision_2
config=/etc/httpd/conf.d/phpMyAdmin.conf
if [[ "$decision_2" =~ ^[yY]$ ]];
then
    sed -i 's/<RequireAny>/#&/' $config 
    sed -i 's/Require ip 127.0.0.1/#&/' $config
    sed -i 's/Require ip ::1/#&/' $config
    sed -i 's/<\/RequireAny>/#&/' $config
    sed -i '/<\/RequireAny>/a Require all granted' $config
fi
mysql_secure_installation
systemctl restart httpd.service
echo '<?php phpinfo();' > /var/www/html/info.php


#
# Permissions
#
a=1
while [ $a -eq 1 ]; do
    echo Which user should be owner of the web files?
    read user
        if grep -q "$user" /etc/passwd
        then
            a=0
       	    chown -R $user /var/www/html /var/www/html/info.php
            chgrp -R $user /var/www/html /var/www/html/info.php
            chmod 755 /var/www/html
            chmod 644 /var/www/html/info.php
        else
            echo This user does not exit. Would you like to create user \"$user\" \[y/n\]
            read decision_3
	        if [[ "$decision_3" =~ ^[Yy]$ ]];
	        then
	            useradd --no-create-home $user
	            a=0
        	    chown -R $user /var/www/html /var/www/html/info.php
        	    chgrp -R $user /var/www/html /var/www/html/info.php
        	    chmod 755 /var/www/html
        	    chmod 644 /var/www/html/info.php
	        fi
        fi
done

echo "" && echo  System won\'t allow acces throught the web browser to any file outside of those located in /var/www/html/ directory
