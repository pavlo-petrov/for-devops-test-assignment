Create manual 
(click-on with using AWS WEB UI)

1. s3 bucket for terraform state.
(do not forget ot activate "version" and "encrypt" like me)

2. secret manager: 
- add MySQL admin's password: 
	- secret name: test_mysql_pass
	- Secret key: password_for_mysql

3. open github repozitory and add: 
    - credential for aws: 
        AWS_ACCESS_KEY
        AWS_SECRET_ACCESS_KEY

4. Create two accounts on Docker Hub:
    - for admin contaner 
    - for work contaner

5. Create your domain and use amazon's NS servers for this. 


database-1 
admin


Pq$oy1Jejz&enk@d3q

aws 
AKIA6GBMGM3JJOOUCV4C




4.
5.
6.
7.
8.

ubuntu@ip-10-0-1-105:~$ cat ./install-wordpress.sh 
#!/bin/bash

# parametrs of MySQL
DB_NAME="wordpress_db"
DB_USER="admin"
DB_PASSWORD="ASDcsxcfsdfSDFSDF123123asdsadasd"
DB_HOST="my-mysql-db.czc486e46x94.eu-west-1.rds.amazonaws.com"

# Параметри WordPress
WP_URL="http://wordpress-for-test.pp.ua"
WP_TITLE="My WordPress Site"
WP_ADMIN_USER="paul"
WP_ADMIN_PASSWORD="ASDcsxcfsdfSDFSDF123123asdsadasd"
WP_ADMIN_EMAIL="admin@wordpress-for-test.pp.ua"

# Оновлення та встановлення необхідних пакетів
sudo apt update
sudo apt install -y apache2 mysql-server php php-mysql libapache2-mod-php wget unzip

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


ubuntu@ip-10-0-1-105:~$ 




variable "docker_hub_username" {}
variable "docker_hub_access_token" {}

  environment_vars = [
      "DOCKER_HUB_USERNAME=${var.docker_hub_username}",
      "DOCKER_HUB_ACCESS_TOKEN=${var.docker_hub_access_token}"
  ]



#!/bin/bash

# параметри MySQL
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

# Встановлення Redis
if ! command -v redis-server &> /dev/null; then
  echo "Redis не встановлений. Встановлюємо Redis..."
  apt-get update
  apt-get install -y redis-server
  systemctl enable redis-server
  systemctl start redis-server
else
  echo "Redis вже встановлений."
fi

# Перевірка наявності бази даних та користувача
DB_EXISTS=$(mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} -e "SHOW DATABASES LIKE '${DB_NAME}';" | grep "${DB_NAME}")
if [ -z "$DB_EXISTS" ]; then
    mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} -e "CREATE DATABASE ${DB_NAME};"
else
    echo "База даних ${DB_NAME} вже існує."
fi

USER_EXISTS=$(mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} -e "SELECT 1 FROM mysql.user WHERE user = '${WP_ADMIN_USER}' AND host = '%';" | grep "1")
if [ -z "$USER_EXISTS" ]; then
    mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} -e "CREATE USER '${WP_ADMIN_USER}'@'%' IDENTIFIED BY '${WP_ADMIN_PASSWORD}';"
    mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${WP_ADMIN_USER}'@'%';"
else
    echo "Користувач ${WP_ADMIN_USER}@% вже існує."
fi

mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} -e "FLUSH PRIVILEGES;"

echo "!!!!!!user added or exist!!!!!!"

# Створення файлу wp-config.php, якщо він не існує
if [ ! -f /var/www/html/wp-config.php ]; then
    cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
    sed -i "s/database_name_here/${DB_NAME}/" /var/www/html/wp-config.php
    sed -i "s/username_here/${WP_ADMIN_USER}/" /var/www/html/wp-config.php
    sed -i "s/password_here/${WP_ADMIN_PASSWORD}/" /var/www/html/wp-config.php
    sed -i "s/localhost/${DB_HOST}/" /var/www/html/wp-config.php
    echo "!!!!!!copied and setuped!!!!!!"
else
    echo "Файл wp-config.php вже існує."
fi

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

# Встановлення та налаштування плагіну для S3
PLUGIN_SLUG="amazon-s3-and-cloudfront"
if ! sudo -u www-data wp plugin is-installed ${PLUGIN_SLUG} --path=/var/www/html/; then
  sudo -u www-data wp plugin install ${PLUGIN_SLUG} --activate --path=/var/www/html/
  # Налаштування плагіну можна додати сюди, наприклад:
  # sudo -u www-data wp config set AS3CF_SETTINGS --add='{"provider":"aws","access-key-id":"YOUR_ACCESS_KEY","secret-access-key":"YOUR_SECRET_KEY","bucket":"YOUR_BUCKET_NAME","region":"YOUR_REGION"}' --type=json --path=/var/www/html/
else
  echo "Плагін ${PLUGIN_SLUG} вже встановлений."
  sudo -u www-data wp plugin activate ${PLUGIN_SLUG} --path=/var/www/html/
fi


{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ListObjectsInBucket",
            "Effect": "Allow",
            "Action": ["s3:ListBucket"],
            "Resource": ["arn:aws:s3:::bucket-name"]
        },
        {
            "Sid": "AllObjectActions",
            "Effect": "Allow",
            "Action": "s3:*Object",
            "Resource": ["arn:aws:s3:::bucket-name/*"]
        }
    ]
}