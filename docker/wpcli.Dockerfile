ARG PHP_VERSION

FROM wordpress:cli-php${PHP_VERSION:-8.3}

USER root
RUN apk add --no-cache patch