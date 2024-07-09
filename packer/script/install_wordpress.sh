#!/bin/bash

# parametrs of MySQL
DB_NAME="wordpress_db"
DB_USER="admin"
DB_PASSWORD: $DB_PASSWORD
DB_HOST: $DB_HOST

# Параметри WordPress
WP_URL="http://wordpress-for-test.pp.ua"
WP_TITLE="My WordPress Site"
WP_ADMIN_USER="admin"
WP_ADMIN_PASSWORD=$DB_PASSWORD
WP_ADMIN_EMAIL="admin@wordpress-for-test.pp.ua"

# Створення бази даних та користувача MySQL
DB_EXISTS=$(mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} -e "SHOW DATABASES LIKE '${DB_NAME}';" | grep "${DB_NAME}")
if [ -z "$DB_EXISTS" ]; then
    mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} -e "CREATE DATABASE ${DB_NAME};"
else
    echo "База даних ${DB_NAME} вже існує."
fi

USER_EXISTS=$(mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} -e "SELECT 1 FROM mysql.user WHERE user = '${DB_USER}' AND host = '${DB_HOST}';" | grep "1")
if [ -z "$USER_EXISTS" ]; then
    mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} -e "CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';"
    mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';"
else
    echo "Користувач ${DB_USER}@${DB_HOST} вже існує."
fi

mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} -e "FLUSH PRIVILEGES;"


# Завантаження та розпаковування WordPress
cd /tmp
wget https://wordpress.org/latest.zip
unzip latest.zip
#sudo rm -rf /var/www/html/*
sudo mv wordpress /var/www/html/wordpress/

# Налаштування прав доступу
sudo chown -R www-data:www-data /var/www/html/wordpress/
sudo chmod -R 755 /var/www/html/wordpress/

# Створення файлу wp-config.php
cp /var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php
sudo sed -i "s/database_name_here/${DB_NAME}/" /var/www/html/wordpress/wp-config.php
sudo sed -i "s/username_here/${DB_USER}/" /var/www/html/wordpress/wp-config.php
sudo sed -i "s/password_here/${DB_PASSWORD}/" /var/www/html/wordpress/wp-config.php
sudo sed -i "s/localhost/${DB_HOST}/" /var/www/html/wordpress/wp-config.php

# Перевірка ��'єднання з базою даних

sudo -u www-data php -r "
\$mysqli = new mysqli('${DB_HOST}', '${DB_USER}', '${DB_PASSWORD}', '${DB_NAME}');
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



# Налаштування Apache
sudo a2enmod rewrite
sudo service apache2 restart

# Автоматичне встановлення WordPress через WP-CLI
cd /var/www/html/wordpress/
wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp



if sudo -u www-data wp core is-installed --path=/var/www/html/wordpress/; then
  echo "WordPress вже встановлений. Пропускаємо установку."
else
  # Виконання установки WordPress
  sudo -u www-data wp core install --url="${WP_URL}" --title="${WP_TITLE}" --admin_user="${WP_ADMIN_USER}" --admin_password="${WP_ADMIN_PASSWORD}" --admin_email="${WP_ADMIN_EMAIL}" --path=/var/www/html/wordpress
  echo "WordPress успішно встановлено!"
fi