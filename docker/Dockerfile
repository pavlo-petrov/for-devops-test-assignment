# Використовуємо офіційний образ PHP з Apache
# #FROM php:7.4-apache
# FROM php:8.2-cli
FROM ubuntu:latest

# Оновлення та встановлення необхідних пакетів
RUN apt update && \
    apt install -y \
    apache2 \
    php \
    php-cli \
    php-common \
    php-imap \
    php-fpm \
    php-snmp \
    php-xml \
    php-zip \
    php-mbstring \
    php-curl \
    php-mysqli \
    php-gd \
    php-intl \
    php-redis \
    curl \
    unzip \
    git \
    wget \
    sudo \
    mysql-client \
    && rm -rf /var/lib/apt/lists/*

# Налаштування Apache
RUN a2enmod rewrite

# Копіюємо файли конфігурації Apache
COPY /packer/script/wordpress-for-test.pp.ua.conf /etc/apache2/sites-available/wordpress-for-test.pp.ua.conf


# Робочий каталог для WordPress
WORKDIR /var/www/wordpress-for-test.pp.ua

# Встановлення WordPress
COPY wordpress/. ./
COPY packer/script/install_wordpress.sh ./


RUN chown -R www-data:www-data /var/www/wordpress-for-test.pp.ua \
    && chmod -R 755 /var/www/wordpress-for-test.pp.ua \
    && chmod +x /var/www/wordpress-for-test.pp.ua/install_wordpress.sh

# 
RUN service apache2 start
RUN a2ensite wordpress-for-test.pp.ua.conf

#
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2


# Відкриття портів Apache
EXPOSE 80

# Запуск Apache у foreground режимі
CMD ["apachectl", "-D", "FOREGROUND"]