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
# Step 1: install everything from the lock file exactly as-is.
# --ignore-platform-reqs bypasses PHP ^7.1 checks in slim/csrf etc.
# --no-audit suppresses security-advisory blocking on twig/extensions.
RUN composer install \
        --no-dev \
        --optimize-autoloader \
        --no-interaction \
        --no-ansi \
        --no-scripts \
        --ignore-platform-reqs \
        --no-security-blocking
# Step 2: slimbus ships phpdotenv ^4.1 in composer.json but index.php uses
# the v2 API (new Dotenv\Dotenv($path)).  Downgrade just that one package.
RUN sed -i 's|"vlucas/phpdotenv": "[^"]*"|"vlucas/phpdotenv": "^2.6"|' composer.json \
    && composer update vlucas/phpdotenv \
        --no-dev \
        --no-scripts \
        --no-interaction \
        --no-ansi \
        --ignore-platform-reqs \
        --no-security-blocking

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
