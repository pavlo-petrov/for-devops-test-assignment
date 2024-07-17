#!/bin/bash

# parametrs of MySQL
DB_NAME=$MYSQL_DATABASE_NAME
DB_USER="admin"
DB_PASSWORD=$DB_PASSWORD
DB_HOST=$DB_HOST

# Параметри WordPress
WP_URL="https://wordpress-for-test.pp.ua"
WP_TITLE="My WordPress Site"
WP_ADMIN_USER=$WP_ADMIN_USER
WP_ADMIN_PASSWORD=$DB_PASSWORD
WP_ADMIN_EMAIL="admin@wordpress-for-test.pp.ua"

# Redis access point
REDIS_ENDPOINT=$REDIS_ENDPOINT

# Параметри для S3
MY_REGION=$AWS_RIGION
MY_S3=$AWS_S3_WORDPRESS_NAME_S3


# Створення файлу wp-config.php
echo "!!!!!!setup started!!!!!!"

sed -i "s/database_name_here/${DB_NAME}/" /var/www/html/wp-config.php
sed -i "s/username_here/${WP_ADMIN_USER}/" /var/www/html/wp-config.php
sed -i "s/password_here/${WP_ADMIN_PASSWORD}/" /var/www/html/wp-config.php
sed -i "s/localhost/${DB_HOST}/" /var/www/html/wp-config.php
sed -i "s/cache.amazonaws.com/${REDIS_ENDPOINT}/" /var/www/html/wp-config.php

echo "!!!!!!copied add setuped!!!!!!"


# Перевірка з'єднання з базою даних
php -r "
\$mysqli = new mysqli('${DB_HOST}', '${WP_ADMIN_USER}', '${WP_ADMIN_PASSWORD}', '${DB_NAME}');
if (\$mysqli->connect_error) {
    die('Connection failed: ' . \$mysqli->connect_error);
} else {
    echo 'Connection successful to database server.';
}
if (!\$mysqli->select_db('${DB_NAME}')) {
    die('Cannot select database: ' . \$mysqli->error);
} else {
    echo 'Database ${DB_NAME} selected successfully.';
}
"

echo "!!!!!!!!connection with db exist or not!!!!!!"

# Виконання установки WordPress
sudo -u www-data wp core install --url="${WP_URL}" --title="${WP_TITLE}" --admin_user="${WP_ADMIN_USER}" --admin_password="${WP_ADMIN_PASSWORD}" --admin_email="${WP_ADMIN_EMAIL}" --path=/var/www/html
sudo -u www-data wp plugin install redis-cache --activate
WP_CONFIG_PATH="/var/www/html/wp-config.php"

# install redis 
sudo -u www-data wp config set WP_REDIS_DATABASE "0"
sudo -u www-data wp redis enable --path=/var/www/html/
sudo -u www-data wp redis status --path=/var/www/html/
sudo -u www-data wp redis update-dropin --path=/var/www/html/

echo "WordPress install or not - but we are in this step!"

# Встановлення та налаштування плагіну для S3
PLUGIN_SLUG="amazon-s3-and-cloudfront"
sudo -u www-data wp plugin install ${PLUGIN_SLUG} --activate --path=/var/www/html/
sudo -u www-data wp config set AS3CF_SETTINGS --add="{\"provider\":\"aws\",\"bucket\":\"${MY_S3}\",\"region\":\"${MY_REGION}\"}" --type=json --path=/var/www/html/
sudo -u www-data wp config set AS3CF_SETTINGS "{"provider":"aws","bucket":"$MY_S3","region":"$MY_REGION"}" --add=true --type=constant --path=/var/www/html/

rm /var/www/html/install_wordpress.sh