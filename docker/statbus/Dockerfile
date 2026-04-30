FROM php:7.4-fpm-bullseye

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
# slimbus index.php uses the phpdotenv v2 API (new Dotenv\Dotenv($path)) but
# composer.json requires ^4.1.  Pin to v2 and drop the lock so it re-resolves.
# PHP 7.4 satisfies slim/csrf ^7.1 natively.
# --no-security-blocking skips the twig/extensions advisory.
RUN sed -i \
        -e 's|"vlucas/phpdotenv": "[^"]*"|"vlucas/phpdotenv": "^2.6"|' \
        -e 's|"slim/slim": "[^"]*"|"slim/slim": "^3.12"|' \
        -e 's|"slim/twig-view": "[^"]*"|"slim/twig-view": "^2.0"|' \
        -e 's|"slim/csrf": "[^"]*"|"slim/csrf": "^0.8"|' \
        composer.json \
    && rm -f composer.lock
RUN composer install \
        --no-dev \
        --optimize-autoloader \
        --no-interaction \
        --no-ansi \
        --no-scripts \
        --no-security-blocking

COPY slimbus/ .

# Regenerate the classmap now that the application source is in place.
RUN composer dump-autoload --optimize --no-interaction --no-ansi

RUN mkdir -p tmp/twig \
    && chown -R www-data:www-data /var/www/html/tmp /var/www/html/public \
    && chmod -R ug+rwX /var/www/html/tmp

COPY docker/statbus/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 9000

# Entrypoint writes .env from Docker env vars then execs php-fpm.
ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]
