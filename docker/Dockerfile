# Використовуємо офіційний образ PHP з Apache
# #FROM php:7.4-apache
# FROM php:8.2-cli
# FROM wordpress:latest
FROM ubuntu:latest

RUN apt update 
RUN apt install -y unzip
RUN apt install -y apache2 php php-mysql php-redis php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip wget unzip mysql-client php-pear php-dev
RUN (echo "no" | sudo pecl install redis) || true
RUN echo "extension=redis.so" > sudo tee /etc/php/$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;')/apache2/conf.d/20-redis.ini

# install redis... 
# RUN pecl install redis && docker-php-ext-enable redis
# Копіюємо файли конфігурації Apache
COPY /packer/script/wordpress-for-test.pp.ua.conf /etc/apache2/sites-available/wordpress-for-test.pp.ua.conf
RUN ln -s /etc/apache2/sites-available/wordpress-for-test.pp.ua.conf /etc/apache2/sites-enabled/wordpress-for-test.pp.ua.conf
RUN a2ensite wordpress-for-test.pp.ua.conf

# Робочий каталог для WordPress
WORKDIR /var/www/html/

# Встановлення WordPress
#COPY wordpress/. ./
COPY packer/script/install_wordpress.sh ./

RUN wget https://downloads.wordpress.org/plugin/redis-cache.latest-stable.zip
RUN unzip redis-cache.latest-stable.zip -d /var/www/html/wp-content/plugins/
RUN mkdir -p /var/www/html/wp-content/plugins
RUN chown -R www-data:www-data /var/www/html \
     && chmod -R 755 /var/www/html \
     && chmod +x /var/www/html/install_wordpress.sh

# Відкриття портів Apache
EXPOSE 80

# Запуск Apache у foreground режимі
CMD ["apachectl", "-D", "FOREGROUND"]