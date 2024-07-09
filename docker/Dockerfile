# Використовуємо офіційний образ PHP з Apache
FROM php:7.4-apache

# Оновлення та встановлення необхідних пакетів
RUN apt update && \
    apt install -y \
    libzip-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    unzip \
    git \
    mysql \
    php-redis \
    && rm -rf /var/lib/apt/lists/*

# Налаштування PHP розширень
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd mysqli zip

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
CMD ["apache2-foreground"]