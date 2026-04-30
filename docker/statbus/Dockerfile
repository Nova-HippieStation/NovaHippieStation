FROM php:8.2-fpm-bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        unzip \
        zip \
        libbz2-dev \
    && docker-php-ext-install -j$(nproc) pdo_mysql bz2 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Install dependencies before copying source for better layer caching.
COPY slimbus/composer.json slimbus/composer.lock ./
RUN composer install \
        --no-dev \
        --optimize-autoloader \
        --no-interaction \
        --no-ansi \
        --no-scripts \
    || composer install \
        --no-dev \
        --optimize-autoloader \
        --no-interaction \
        --no-ansi \
        --no-scripts \
        --ignore-platform-reqs

COPY slimbus/ .

RUN mkdir -p tmp/twig \
    && chown -R www-data:www-data /var/www/html/tmp /var/www/html/public \
    && chmod -R ug+rwX /var/www/html/tmp

COPY docker/statbus/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 9000

# Entrypoint writes .env from Docker env vars then execs php-fpm.
ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]
