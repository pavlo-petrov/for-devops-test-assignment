#!/bin/bash

# parametrs of MySQL
DB_NAME="wordpress_db"
DB_USER="admin"
DB_PASSWORD=$DB_PASSWORD
DB_HOST=$DB_HOST

# Параметри WordPress
WP_URL="http://wordpress-for-test.pp.ua"
WP_TITLE="My WordPress Site"
WP_ADMIN_USER="paul"
WP_ADMIN_PASSWORD=$DB_PASSWORD
WP_ADMIN_EMAIL="admin@wordpress-for-test.pp.ua"

# Створення бази даних та користувача MySQL
echo "DB_HOST: $DB_HOST"
echo "DB_PASSWORD: $DB_PASSWORD"

DB_EXISTS=$(mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} -e "SHOW DATABASES LIKE '${DB_NAME}';" | grep "${DB_NAME}")
if [ -z "$DB_EXISTS" ]; then
    mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} -e "CREATE DATABASE ${DB_NAME};"
else
    echo "База даних ${DB_NAME} вже існує."
fi

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
cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
sed -i "s/database_name_here/${DB_NAME}/" /var/www/html/wp-config.php
sed -i "s/username_here/${WP_ADMIN_USER}/" /var/www/html/wp-config.php
sed -i "s/password_here/${WP_ADMIN_PASSWORD}/" /var/www/html/wp-config.php
sed -i "s/localhost/${DB_HOST}/" /var/www/html/wp-config.php

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

echo "!!!!!!!!connection with db exist!!!!!!"

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

if sudo -u www-data wp core is-installed --path=/var/www/html/; then
  echo "WordPress вже встановлений. Пропускаємо установку."
else
  # Виконання установки WordPress
  sudo -u www-data wp core install --url="${WP_URL}" --title="${WP_TITLE}" --admin_user="${WP_ADMIN_USER}" --admin_password="${WP_ADMIN_PASSWORD}" --admin_email="${WP_ADMIN_EMAIL}" --path=/var/www/html
  sudo -u www-data wp plugin install redis-cache --activate
  WP_CONFIG_PATH="/var/www/html/wp-config.php"
if ! grep -q "WP_REDIS_HOST" "$WP_CONFIG_PATH"; then
  echo "define('WP_REDIS_HOST', '$REDIS_ENDPOINT');" >> "$WP_CONFIG_PATH"
  echo "define('WP_REDIS_PORT', 6379);" >> "$WP_CONFIG_PATH"
  echo "define('WP_CACHE', true);" >> "$WP_CONFIG_PATH"
fi
  wp redis enable
  echo "WordPress успішно встановлено!"
fi