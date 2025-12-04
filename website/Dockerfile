FROM php:8.2-apache

# Installeer PDO MySQL extensie
RUN docker-php-ext-install pdo pdo_mysql

# Kopieer website bestanden
COPY . /var/www/html/

# Stel Apache configuratie in
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Stel permissies in
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

# Expose poort 80
EXPOSE 80

CMD ["apache2-foreground"]