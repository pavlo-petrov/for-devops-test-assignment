#!/bin/bash

# parametrs of MySQL
DB_NAME="wordpress_db"
DB_USER="admin"
DB_PASSWORD=$DB_PASSWORD
DB_HOST=$DB_HOST
REDISD_HOST=$
REDISD_PORT=$


# Параметри WordPress
WP_URL="http://wordpress-for-test.pp.ua"
WP_TITLE="My WordPress Site"
WP_ADMIN_USER="paul"
WP_ADMIN_PASSWORD=$DB_PASSWORD
WP_ADMIN_EMAIL="admin@wordpress-for-test.pp.ua"

# Створення бази даних та користувача MySQL
mysql_command="DB_EXISTS=\$(mysql -h \${DB_HOST} -u \${DB_USER} -p\${DB_PASSWORD} -e \"SHOW DATABASES LIKE '\${DB_NAME}';\" | grep \"\${DB_NAME}\")
if [ -z \"\$DB_EXISTS\" ]; then
    mysql -h \${DB_HOST} -u \${DB_USER} -p\${DB_PASSWORD} -e \"CREATE DATABASE \${DB_NAME};\"
else
    echo \"База даних \${DB_NAME} вже існує.\"
fi"

# Команда для налаштування WordPress
wordpress_command="wp core install --url=\${WP_URL} --title='\${WP_TITLE}' --admin_user=\${WP_ADMIN_USER} --admin_password=\${WP_ADMIN_PASSWORD} --admin_email=\${WP_ADMIN_EMAIL}"

# Виконання команд в Docker контейнері
docker exec my-container /bin/bash -c "\
  DB_HOST='$DB_HOST' \
  DB_USER='$DB_USER' \
  DB_PASSWORD='$DB_PASSWORD' \
  DB_NAME='$DB_NAME' \
  WP_URL='$WP_URL' \
  WP_TITLE='$WP_TITLE' \
  WP_ADMIN_USER='$WP_ADMIN_USER' \
  WP_ADMIN_PASSWORD='$WP_ADMIN_PASSWORD' \
  WP_ADMIN_EMAIL='$WP_ADMIN_EMAIL' \
  $mysql_command && $wordpress_command"