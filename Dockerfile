FROM nextcloud:latest
# gnupg is a required for adding the Postgres key
RUN apt update && apt install -y gnupg
RUN curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null

# As of writing, NC is using `bullseye` and unable to install lsb-release with ease, so hardcoded
# To be replaced by cat /etc/os-release | grep VERSION_CODENAME | awk -F "=" '{print $2}'
#RUN version=$(cat /etc/os-release | grep VERSION_ID | awk -F '"' '{print $2}'); \
#    version_name=$(cat /etc/os-release | grep VERSION_CODENAME | awk -F "=" '{print $2}'); \
#    debrelease=$(if [ $version -lt 12 ]; then echo "bookworm";else echo $version_name;fi); \
#    echo "deb http://apt.postgresql.org/pub/repos/apt $debrelease-pgdg main" > /etc/apt/sources.list.d/pgdg.list; \
#    sed -i -e "s|bullseye|$debrelease|g" /etc/apt/sources.list;

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
    postgresql-client-15 \
    fail2ban \
    openssh-server \
    procps \
    smbclient \
    ffmpeg; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*; \
    pip3 install svglib; \
    rm -rf /var/lib/apt/lists/*; \
    mkdir /var/log/supervisord /var/run/supervisord;

# Package with wich Backup-App can talk to Postgres using PHP
# See https://stackoverflow.com/questions/47603398/docker-php-with-pdo-pgsql-install-issue
RUN docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql; \
    docker-php-ext-install pdo pdo_pgsql pgsql bz2 smbclient imap ffmpeg avconf LibreOffice

# Fail2ban
RUN touch /var/log/auth.log

COPY supervisord.conf /
COPY config/fail2ban/fail2ban.conf /etc/fail2ban/filter.d/nextcloud.conf
COPY config/fail2ban/jail.conf /etc/fail2ban/jail.d/nextcloud.local
COPY config/env/sudo_env /etc/sudoers.d/
COPY config/env/environment /etc/environment

RUN chmod 764 /etc/sudoers.d/sudo_env;

ENV NEXTCLOUD_UPDATE=1


#RUN sed -i \
#    -e ':a;N;$!ba;s|  <IfModule mod_env.c>\n    # Add security and privacy related headers|  <IfModule mod_env.c>\n    # Add security and privacy related headers\n    Header always set Strict-Transport-Security "max-age=15552000; includeSubDomains"\n    SetEnv front_controller_active true|' \
#    -e 's|    Header always set X-Content-Type-Options "nosniff"|    Header always set X-Content-Type-Options "nosniff"\n\n    Header onsuccess unset X-Download-Options\n    Header always set X-Download-Options "noopen"\n|g' \
#    -e 's|dav /remote.php/dav/ |dav https://%{SERVER_NAME}/remote.php/dav/ |g' \
#    /var/www/html/.htaccess;

RUN sed -i \
    -e ':a;N;$!ba;s|opcache.memory_consumption=128|opcache.memory_consumption=512|g' \
    /usr/local/etc/php/conf.d/opcache-recommended.ini;

CMD rm /var/run/fail2ban/fail2ban.sock; \
    service fail2ban restart; \
    /usr/bin/supervisord -c /supervisord.conf
