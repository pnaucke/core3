FROM php:8.2-apache

# Verwijder oude bestanden
RUN rm -rf /var/www/html/*

# Kopieer de nieuwe website
COPY ./ /var/www/html/

# Zet juiste rechten voor Apache
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Apache configuratie aanpassen
RUN echo '<Directory /var/www/html>\n\
    Options Indexes FollowSymLinks\n\
    AllowOverride All\n\
    Require all granted\n\
</Directory>' > /etc/apache2/conf-available/website.conf \
    && a2enconf website

# Modules inschakelen
RUN a2enmod rewrite

EXPOSE 80

CMD ["apache2-foreground"]
