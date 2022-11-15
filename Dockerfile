FROM php:7.4.33-apache-bullseye
MAINTAINER Ricardo Coelho <rcoelho@mpma.mp.br>

COPY assets/oracle /opt/oracle/
COPY assets/php.ini /usr/local/etc/php/
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        git \
        sudo \
        libpq-dev \
        libicu-dev \
        libcurl4-openssl-dev \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        libxslt1-dev \
        libldb-dev \
        libzip-dev \
        libzstd-dev \
        libmemcached-dev \
        freetds-dev \        
        build-essential \
        libaio1 \
        libldap2-dev \
        smbclient \
        liblz4-dev \
        libmemcached-dev \
    && sed -i "s/syslog = 0/#syslog = 0/g" /etc/samba/smb.conf \
    && ln -s /usr/lib/x86_64-linux-gnu/libldap.so /usr/lib/libldap.so \
    && ln -s /usr/lib/x86_64-linux-gnu/liblber.so /usr/lib/liblber.so \
    && docker-php-ext-install -j$(nproc) pgsql pdo_pgsql pdo_mysql ldap xsl gettext mysqli \
    && docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd intl zip \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && chmod +x /usr/local/bin/composer \
    && docker-php-ext-install bcmath \
    && yes "no" | pecl install -f -o lzf \
    && yes "yes" | pecl install -f -o igbinary msgpack redis \
    && pecl install -f -o --onlyreqdeps --nobuild memcached-3.1.3 \
    && cd "$(pecl config-get temp_dir)/memcached" \
    && phpize \ 
    && ./configure --with-php-config=/usr/local/bin/php-config --with-libmemcached-dir --with-zlib-dir --with-system-fastlz=no --enable-memcached-igbinary=yes --enable-memcached-msgpack=yes --enable-memcached-json=yes --enable-memcached-protocol=no --enable-memcached-sasl=yes --enable-memcached-session=yes \
    && make && make install \
    && docker-php-ext-enable lzf igbinary msgpack redis \
    && docker-php-ext-enable memcached \
    && cd - \
    && gunzip /opt/oracle/instantclient_12_2/*.gz \
    && ln /opt/oracle/instantclient_12_2/libclntsh.so.12.1 /opt/oracle/instantclient_12_2/libclntsh.so \
    && ln /opt/oracle/instantclient_12_2/libocci.so.12.1 /opt/oracle/instantclient_12_2/libocci.so \
    && echo "/opt/oracle/instantclient_12_2" > /etc/ld.so.conf.d/oracle-instantclient.conf \
    && ldconfig \
    && echo "instantclient,/opt/oracle/instantclient_12_2" | pecl install oci8-2.2.0 \
    && docker-php-ext-configure pdo_oci \
       --with-pdo-oci=instantclient,/opt/oracle/instantclient_12_2,12.2 \
    && docker-php-ext-install pdo_oci \
    && docker-php-ext-configure oci8 --with-oci8=instantclient,/opt/oracle/instantclient_12_2 \
    && docker-php-ext-install oci8 \
    && ln -s /usr/lib/x86_64-linux-gnu/libsybdb.a /usr/lib/ \
    && docker-php-ext-configure pdo_dblib \
    && docker-php-ext-install pdo_dblib
