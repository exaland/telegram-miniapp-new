# syntax=docker/dockerfile:1

### Stage 1: Build with Composer
FROM php:8.2-apache AS builder

ARG COMPOSER_ALLOW_SUPERUSER=1

# Installer dépendances système nécessaires
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    unzip \
    libzip-dev \
    libonig-dev \
    libpng-dev \
    libfreetype6-dev \
    libjpeg-dev \
    libxml2-dev \
    pkg-config \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Installer extensions PHP (y compris pcntl pour Composer)
RUN docker-php-ext-configure gd --with-jpeg --with-freetype \
 && docker-php-ext-install -j"$(nproc)" gd mbstring zip pdo pdo_mysql xml pcntl

# Activer rewrite pour Apache (utile si le projet en a besoin)
RUN a2enmod rewrite

# Installer Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Préparer workspace
WORKDIR /app
COPY composer.json composer.lock* /app/

# Installer dépendances (no-dev)
RUN composer install --no-dev --no-scripts --prefer-dist --no-interaction --optimize-autoloader

# Copier le reste de l’application
COPY . /app

# Finaliser l’installation (assure vendor, scripts, etc.)
RUN composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader

### Stage 2: Runtime léger
FROM php:8.2-apache

# Installer dépendances runtime
RUN apt-get update && apt-get install -y --no-install-recommends \
    libzip-dev \
    libonig-dev \
    libpng-dev \
    libfreetype6-dev \
    libjpeg-dev \
    libxml2-dev \
 && rm -rf /var/lib/apt/lists/*

# Réinstaller extensions PHP
RUN docker-php-ext-configure gd --with-jpeg --with-freetype \
 && docker-php-ext-install -j"$(nproc)" gd mbstring zip pdo pdo_mysql xml pcntl

# Activer rewrite pour Apache
RUN a2enmod rewrite

# Définir répertoire de travail
WORKDIR /var/www/html

# Copier application depuis le builder
COPY --from=builder /app /var/www/html


# Installer Composer globalement
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
 && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
 && php -r "unlink('composer-setup.php');"


# Composer install
RUN composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader

# Configurer DocumentRoot si nécessaire
# RUN sed -ri 's!DocumentRoot /var/www/html!DocumentRoot /var/www/html!g' \
#     /etc/apache2/sites-available/000-default.conf \
#  && sed -ri 's!<Directory /var/www/>!<Directory /var/www/html/>!g' \
#     /etc/apache2/apache2.conf

# Ajuster permissions
RUN chown -R www-data:www-data /var/www/html \
 && find /var/www/html -type f -exec chmod 644 {} \; \
 && find /var/www/html -type d -exec chmod 755 {} \;

# Exposer le port HTTP
EXPOSE 80

# Démarrer Apache
CMD ["apache2-foreground"]
