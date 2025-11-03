FROM php:8.2-fpm

# Installer dépendances et extensions PHP pour PostgreSQL
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    libpq-dev \
    libonig-dev \
    curl \
    zip \
    && docker-php-ext-install pdo pdo_pgsql mbstring zip

# Installer Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Créer un utilisateur non-root
RUN useradd -m -s /bin/bash laravel

# Copier le projet
WORKDIR /var/www
COPY . .

# Changer les permissions avant l'installation des dépendances
RUN chown -R laravel:laravel /var/www

# Installer les dépendances PHP en tant qu'utilisateur laravel
USER laravel
RUN composer install --no-dev --optimize-autoloader

# Revenir à root pour les permissions finales
USER root
RUN mkdir -p storage/framework/{cache,data,sessions,testing,views} \
    && mkdir -p storage/logs \
    && mkdir -p bootstrap/cache \
    && chown -R laravel:laravel /var/www \
    && chmod -R 775 storage bootstrap/cache

# Générer la clé d'application et optimiser
USER laravel
RUN php artisan key:generate --force && \
    php artisan config:cache && \
    php artisan route:cache && \
    php artisan view:cache
USER root

# Copier le script d'entrée
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Passer à l'utilisateur non-root
USER laravel

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["php-fpm"]
