FROM php:8.2-apache

# Installeer PDO MySQL extensie
RUN docker-php-ext-install pdo pdo_mysql

# Zet Apache document root
ENV APACHE_DOCUMENT_ROOT /var/www/html
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Kopieer website bestanden
COPY *.php /var/www/html/
COPY *.css /var/www/html/

# Maak database configuratie aanpasbaar
RUN chown -R www-data:www-data /var/www/html