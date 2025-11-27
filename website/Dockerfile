# Gebruik PHP 8.2 met Apache
FROM php:8.2-apache

# Verwijder eventuele oude bestanden uit de webroot
RUN rm -rf /var/www/html/*

# Kopieer alle bestanden uit de website folder naar de web root
COPY . /var/www/html/

# Zet de juiste rechten voor Apache
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Expose poort 80 voor HTTP verkeer
EXPOSE 80

# Start Apache in de foreground
CMD ["apache2-foreground"]

