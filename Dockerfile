FROM php:8.2-apache

RUN docker-php-ext-install pdo pdo_mysql

COPY website/ /var/www/html/

RUN chown -R www-data:www-data /var/www/html

RUN echo "DirectoryIndex index.php index.html" > /etc/apache2/conf-available/directory-index.conf
RUN a2enconf directory-index

CMD ["apache2-foreground"]