#!/bin/bash

# parametrs of MySQL
DB_NAME="wordpress_db"
DB_USER="admin"
DB_PASSWORD=$DB_PASSWORD
DB_HOST=$DB_HOST

# Параметри WordPress
WP_URL="https://wordpress-for-test.pp.ua"
WP_TITLE="My WordPress Site"
WP_ADMIN_USER="paul"
WP_ADMIN_PASSWORD=$DB_PASSWORD
WP_ADMIN_EMAIL="admin@wordpress-for-test.pp.ua"

# Redis access point
REDIS_ENDPOINT=$REDIS_ENDPOINT

# Параметри для S3
MY_REGION=$AWS_RIGION
MY_S3=$AWS_S3_WORDPRESS_NAME_S3

# Створення бази даних та користувача MySQL
echo "DB_NAME" 
echo "$DB_NAME"
echo "DB_NAME OK"
echo "DB_HOST: $DB_HOST"
echo "DB_USER: $DB_USER"


# cat << EOF > /tmp/my.cnf
# [client]
# user=${DB_USER}
# password=${DB_PASSWORD}
# host=${DB_HOST}
# EOF

# DB_EXISTS=$(mysql --defaults-extra-file=/tmp/my.cnf --silent --skip-column-names -e "SHOW DATABASES LIKE '${DB_NAME}';" 2>/dev/null | grep "${DB_NAME}")
# if [ -z "$DB_EXISTS" ]; then
#     mysql --defaults-extra-file=/tmp/my.cnf -e "CREATE DATABASE ${DB_NAME};"
# else
#     echo "База даних ${DB_NAME} вже існує."
# fi

# rm -f /tmp/my.cnf
# echo "rm /tmp/my.cnf" 


# # Перевірка наявності необхідних змінних оточення
# if [ -z "${DB_HOST}" ] || [ -z "${DB_USER}" ] || [ -z "${DB_PASSWORD}" ] || [ -z "$DB_NAME" ]; then 
#     echo "DB_HOST: $DB_HOST" \
#     echo "DB_USER: $DB_USER" \
#     echo "DB_NAME: $DB_NAME" 
#     echo "Помилка: Потрібно встановити змінні оточення DB_HOST, DB_USER, DB_PASSWORD, DB_NAME." \
#     exit 1 
# else  
#     echo "Змінні оточення встановлені коректно." \
#     echo "DB_HOST: $DB_HOST" \
#     echo "DB_USER: $DB_USER" \
#     echo "DB_NAME: $DB_NAME" 
# fi 

echo "create database" 

DB_EXISTS=$(mysql -h "${DB_HOST}" -u "${DB_USER}" -p"${DB_PASSWORD}" -e "SHOW DATABASES LIKE ${DB_NAME};" | grep "${DB_NAME}")
echo "create database2" 

if [ -z "$DB_EXISTS" ]; then
    mysql -h "${DB_HOST}" -u "${DB_USER}" -p"${DB_PASSWORD}" -e "CREATE DATABASE ${DB_NAME};"
else
    echo "База даних ${DB_NAME} вже існує."
fi

echo "create database" 
echo "create database" 
echo "create database" 
DB_EXISTS=$(mysql -h "${DB_HOST}" -u "${DB_USER}" -p"${DB_PASSWORD}" -e "SHOW DATABASES LIKE '${DB_NAME}';" 2>/dev/null | grep "${DB_NAME}")
echo "db_exists setted" 

if [ -z "$DB_EXISTS" ]; then
     # Створення бази даних, якщо вона не існує
     mysql -h "${DB_HOST}" -u "${DB_USER}" -p"${DB_PASSWORD}" -e "CREATE DATABASE ${DB_NAME};"
     if [ $? -eq 0 ]; then
         echo "База даних ${DB_NAME} успішно створена."
     else
         echo "Помилка: Не вдалося створити базу даних ${DB_NAME}."
     fi
 else
     echo "База даних "${DB_NAME}" вже існує."
 fi

echo "database created or not" 


USER_EXISTS=$(mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} -e "SELECT 1 FROM mysql.user WHERE user = '${DB_USER}' AND host = '${DB_HOST}';" | grep "1")
if [ -z "$USER_EXISTS" ]; then
    mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} -e "CREATE USER '${WP_ADMIN_USER}'@'%' IDENTIFIED BY '${WP_ADMIN_PASSWORD}';"
    mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${WP_ADMIN_USER}'@'%';"
else
    echo "Користувач ${WP_ADMIN_USER}@${DB_HOST} вже існує."
fi

mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} -e "FLUSH PRIVILEGES;"

echo "!!!!!!user added or exist!!!!!!"

# Створення файлу wp-config.php
sudo -u www-data cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
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

# Налаштування Apache
a2enmod rewrite
apachectl graceful
echo "!!!!!! apache restarted correct !!!!!!"

# Автоматичне встановлення WordPress через WP-CLI
cd /var/www/html/
wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp

echo "!!!!!!!!!!wp client is installed or not!!!!!!!"

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
