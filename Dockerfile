FROM php:8.2-apache

RUN docker-php-ext-install pdo pdo_mysql

ENV APACHE_DOCUMENT_ROOT /var/www/html
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# BELANGRIJK: Kopieer ALLES uit website/ map (niet alleen .php en .css)
COPY website/ /var/www/html/

# Zorg dat Apache index.php als standaard bestand herkent
RUN echo "DirectoryIndex index.php index.html" > /etc/apache2/conf-available/directory-index.conf
RUN a2enconf directory-index

RUN chown -R www-data:www-data /var/www/html