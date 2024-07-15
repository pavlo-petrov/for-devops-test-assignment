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
    && rm -rf /var/lib/apt/lists/*

# Налаштування Apache
RUN a2enmod rewrite

# Копіюємо файли конфігурації Apache
# COPY apache-config.conf /etc/apache2/sites-available/000-default.conf

# Робочий каталог для WordPress
WORKDIR /var/www/html

# Встановлення WordPress
COPY wordpress/. ./
COPY packer/script/install_wordpress.sh ./


RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && chmod +x /var/www/html/install_wordpress.sh

# Відкриття портів Apache
EXPOSE 80

# Запуск Apache у foreground режимі
CMD ["apachectl", "-D", "FOREGROUND"]