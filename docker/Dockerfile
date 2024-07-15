# Використовуємо офіційний образ PHP з Apache
# #FROM php:7.4-apache
# FROM php:8.2-cli
FROM wordpress:latest

RUN apt update 
RUN apt install -y sudo 
RUN apt install -y default-mysql-client

# install redis... 
# RUN pecl install redis && docker-php-ext-enable redis
# Копіюємо файли конфігурації Apache
COPY /packer/script/wordpress-for-test.pp.ua.conf /etc/apache2/sites-available/wordpress-for-test.pp.ua.conf


# Робочий каталог для WordPress
WORKDIR /var/www/html/

# Встановлення WordPress
COPY wordpress/. ./
COPY packer/script/install_wordpress.sh ./

RUN chmod +x /var/www/html/install_wordpress.sh

# RUN chown -R www-data:www-data /var/www/html \
#     && chmod -R 755 /var/www/html \
#     && chmod +x /var/www/html/install_wordpress.sh

# 
RUN service apache2 start
RUN a2ensite wordpress-for-test.pp.ua.conf

#
# ENV APACHE_RUN_USER www-data
# ENV APACHE_RUN_GROUP www-data
# ENV APACHE_LOG_DIR /var/log/apache2


# Відкриття портів Apache
EXPOSE 80

# Запуск Apache у foreground режимі
CMD ["apachectl", "-D", "FOREGROUND"]