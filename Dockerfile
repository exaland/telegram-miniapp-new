# syntax=docker/dockerfile:1

### Stage 1: dependencies & build (composer)
FROM php:8.2-apache AS builder

# Arguments
ARG COMPOSER_ALLOW_SUPERUSER=1

# Install system deps & PHP extensions commonly needed
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    unzip \
    libzip-dev \
    libonig-dev \
    libpng-dev \
    libfreetype6-dev \
    libjpeg-dev \
    ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-configure gd --with-jpeg --with-freetype \
  && docker-php-ext-install -j$(nproc) gd mbstring zip pdo pdo_mysql xml

# Enable apache rewrite
RUN a2enmod rewrite

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Set working dir and copy only composer files first (layer caching)
WORKDIR /app
COPY composer.json composer.lock* /app/

# Install composer dependencies (no dev)
RUN composer install --no-dev --no-scripts --prefer-dist --no-interaction --optimize-autoloader

# Copy application
COPY . /app

# Run composer scripts (if any) and install (this ensures vendor exists if composer.lock present)
RUN composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader

### Stage 2: runtime image
FROM php:8.2-apache

# Copy PHP extensions already built in builder stage
# (we need to repeat extension installation in runtime to ensure availability)
FROM php:latest

# Update package list and install dependencies
RUN apt-get update && apt-get install -y \
    libxml2-dev \
    libfreetype6-dev \
    libjpeg-dev \
    libzip-dev \
    unzip \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd mbstring zip pdo pdo_mysql xml

RUN docker-php-ext-configure gd --with-jpeg --with-freetype \
  && docker-php-ext-install -j$(nproc) gd mbstring zip pdo pdo_mysql xml

# Enable apache rewrite
RUN a2enmod rewrite

# Set working dir
WORKDIR /var/www/html

# Copy app from builder
COPY --from=builder /app /var/www/html

# Use /var/www/html/public as DocumentRoot
RUN sed -ri 's!DocumentRoot /var/www/html!DocumentRoot /var/www/html/public!g' /etc/apache2/sites-available/000-default.conf \
 && sed -ri 's!<Directory /var/www/>!<Directory /var/www/html/public/>!g' /etc/apache2/apache2.conf

# Ensure correct permissions (adjust as needed)
RUN chown -R www-data:www-data /var/www/html \
 && find /var/www/html -type f -exec chmod 644 {} \; \
 && find /var/www/html -type d -exec chmod 755 {} \;

# Expose port 80
EXPOSE 80

# Default command
CMD ["apache2-foreground"]
