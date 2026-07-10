FROM php:8.3-cli

# Install dependencies sistem
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    libsqlite3-dev \
    && docker-php-ext-install pdo pdo_sqlite zip \
    && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app

# Copy composer files dulu untuk cache layer
COPY composer.json composer.lock* ./
RUN composer config --global audit.block-insecure false \
    && composer install --no-dev --no-scripts --no-interaction --prefer-dist

# Copy sisa project
COPY . .

# Generate autoload & optimize
RUN composer dump-autoload --optimize

# Siapkan .env dan database sqlite
RUN cp .env.example .env || true
RUN mkdir -p database && touch database/database.sqlite
RUN php artisan key:generate --force || true

# Set permission storage
RUN chmod -R 775 storage bootstrap/cache

EXPOSE 8000

CMD php artisan migrate --force && php artisan serve --host=0.0.0.0 --port=8000
