FROM nextcloud:latest

RUN apt-get update && apt-get install -y \
    supervisor \
    libmagickcore-6.q16-6-extra \
    python3-pip \
    ghostscript \
    pdftk \
  && pip3 install svglib \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir /var/log/supervisord /var/run/supervisord

COPY supervisord.conf /

ENV NEXTCLOUD_UPDATE=1

CMD sed -i \
        -e ':a;N;$!ba;s|  <IfModule mod_env.c>\n    SetEnv front_controller_active true|  <IfModule mod_env.c>\n    Header always set Strict-Transport-Security "max-age=15552000; includeSubDomains"\n    SetEnv front_controller_active true|' \
        -e 's|dav /remote.php/dav/ |dav https://%{SERVER_NAME}/remote.php/dav/ |g' \
        /var/www/html/.htaccess; \
    /usr/bin/supervisord -c /supervisord.conf
