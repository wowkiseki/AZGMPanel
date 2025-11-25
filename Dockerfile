# Use an official PHP image with Apache
FROM php:8.1-apache

# Install system dependencies and PHP extensions
RUN apt-get update && apt-get install -y \
        libzip-dev \
        unzip \
    && docker-php-ext-install pdo_mysql mbstring soap intl json openssl zip

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set the working directory
WORKDIR /var/www/html

# Copy composer files and install dependencies
COPY composer.json ./
RUN composer install --no-dev --optimize-autoloader

# Copy the rest of the application code
COPY . .

# Configure Apache to use the public directory and enable rewrites
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf
RUN a2enmod rewrite

# Create writable directories and set permissions
RUN mkdir -p storage/logs storage/cache config/generated
RUN chown -R www-data:www-data storage config/generated
RUN chmod -R 775 storage config/generated

# Expose port 80
EXPOSE 80

# Start Apache
CMD ["apache2-foreground"]
