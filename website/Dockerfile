FROM php:8.2-apache

# Installeer PDO MySQL extensie
RUN docker-php-ext-install pdo pdo_mysql

# Installeer curl voor health check
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Zet Apache document root
ENV APACHE_DOCUMENT_ROOT /var/www/html
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Kopieer website bestanden
COPY *.php /var/www/html/
COPY *.css /var/www/html/

# Maak een health check endpoint
RUN echo '<?php header("Content-Type: application/json"); echo json_encode(["status": "healthy", "service": "innovatech", "timestamp": date("c")]); ?>' > /var/www/html/health.php

# Maak database configuratie aanpasbaar
RUN chown -R www-data:www-data /var/www/html