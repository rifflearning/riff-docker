FROM nginx
LABEL Description="This image is used to start the rhythm reverse proxy server"

# Remove any existing sample configurations so they don't get loaded
RUN rm /etc/nginx/conf.d/*.conf

# Copy our nginx configuration files into the image
COPY conf /etc/nginx/

# Copy the favicon content into the image, while the other (more dynamic)
# content will be supplied via a bound volume
COPY favicon.ico /usr/share/nginx/html/favicon.ico

# Expose both the standard http and standard https ports
EXPOSE 80 443
