#!/bin/bash

function initialiser_db {
    service mariadb stop
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
    service mariadb start
    mysql -uroot -e "CREATE USER 'admin'@'localhost' IDENTIFIED BY 'admin'; GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;"
    mysql -uroot -e "FLUSH PRIVILEGES;"
}

function initialiser_parametres {
    mkdir -p /etc/pmb
    touch /etc/pmb/db_param.inc.php
    chown www-data:www-data /etc/pmb/db_param.inc.php
    ln -sf /etc/pmb/db_param.inc.php /var/www/html/pmb/includes/db_param.inc.php
    ln -sf /etc/pmb/db_param.inc.php /var/www/html/pmb/opac_css/includes/opac_db_param.inc.php
}

# Créer les paramètres si le fichier n'existe pas
if [ ! -f /var/www/html/pmb/includes/db_param.inc.php ]; then
    initialiser_parametres
fi

# Démarrer MariaDB
service mariadb start --character-set-server=utf8 --collation-server=utf8_unicode_ci --sql_mode=NO_AUTO_CREATE_USER --key_buffer_size=1000000000 --join_buffer_size=4000000

# Vérifier si MySQL est déjà initialisé
if [ ! -d "/var/lib/mysql/mysql" ]; then
    initialiser_db
else
    echo "Base de données déjà initialisée, démarrage de MariaDB..."
    service mariadb start
    mysql_upgrade -u root
fi

# Démarrer PHP-FPM et NGINX
service php8.1-fpm start
nginx -g 'daemon off;'
