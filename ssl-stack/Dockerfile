FROM nginx:latest

RUN apt-get update && \
    apt-get -q -y install certbot

VOLUME ["/etc/letsencrypt"]
