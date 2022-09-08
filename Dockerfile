FROM nextcloud:latest
# gnupg is a required for adding the Postgres key
RUN apt update && apt install -y gnupg
RUN curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null

# As of writing, NC is using `bullseye` and unable to install lsb-release with ease, so hardcoded
# To be replaced by cat /etc/os-release | grep VERSION_CODENAME | awk -F "=" '{print $2}'
RUN echo "deb http://apt.postgresql.org/pub/repos/apt bullseye-pgdg main" > /etc/apt/sources.list.d/pgdg.list

# Install libpq-dev for PHP-Extension pgsql
# Install postgresql-client-10 and postgresql-dev for Backup-App   
RUN apt-get update && apt-get install -y \
    sudo \
    supervisor \
    libmagickcore-6.q16-6-extra \
    python3-pip \
    ghostscript \
    pdftk \
    libpq-dev \
    postgresql-client-10 \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/* \
  && pip3 install svglib \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir /var/log/supervisord /var/run/supervisord
  
# Package with wich Backup-App can talk to Postgres using PHP
# See https://stackoverflow.com/questions/47603398/docker-php-with-pdo-pgsql-install-issue
RUN docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-install pdo pdo_pgsql pgsql

COPY supervisord.conf /
COPY sudo_env /etc/sudoers.d/
COPY environment /etc/environment

ENV NEXTCLOUD_UPDATE=1

CMD sed -i \
        -e ':a;N;$!ba;s|  <IfModule mod_env.c>\n    # Add security and privacy related headers|  <IfModule mod_env.c>\n    # Add security and privacy related headers\n    Header always set Strict-Transport-Security "max-age=15552000; includeSubDomains"\n    SetEnv front_controller_active true|' \
        -e 's|    Header always set X-Content-Type-Options "nosniff"|    Header always set X-Content-Type-Options "nosniff"\n\n    Header onsuccess unset X-Download-Options\n    Header always set X-Download-Options "noopen"\n|g' \
        -e 's|dav /remote.php/dav/ |dav https://%{SERVER_NAME}/remote.php/dav/ |g' \
        /var/www/html/.htaccess; \
    chmod 764 /etc/sudoers.d/sudo_env; \
    sudo -u www-data /var/www/html/occ maintenance:update:htaccess; \
    /usr/bin/supervisord -c /supervisord.conf
