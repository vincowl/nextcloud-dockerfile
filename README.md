![foo](https://github.com/vincowl/nextcloud-dockerfile/actions/workflows/dockerhub.yml/badge.svg)
# nextcloud-dockerfile
New dockerfile based on `nextcloud:latest` to add custom services :
* SVG support
* cron services inside the container
* Resolves .htaccess troubles
* Add dependencies to allow run of [PDF Annotate](https://gitlab.com/nextcloud-other/nextcloud-annotate.git) app : gs, pdftk, pip3 and svglib (svg2pdf). This app shall be installed manually.
