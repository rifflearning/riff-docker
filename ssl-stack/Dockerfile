FROM nginx:latest

RUN echo 'deb http://ftp.debian.org/debian stretch-backports main' >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get -q -y install certbot -t stretch-backports
