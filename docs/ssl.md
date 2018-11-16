# Manually getting LetsEncrypt SSL certs for AWS Docker Swarm #

## Notes ##

I'm trying to streamline some of this by creating an image based on
nginx which already has certbot installed. Whether that is actually
faster is yet to be determined. But I've created an `ssl-stack`
subdirectory in the riff-docker repo with files in it that should
use the following **UNTESTED** commands:

```sh
cd ssl-stack
docker-compose build
docker-compose push
docker stack deploy -c docker-compose.yml ssl-stack
```

Then follow the steps below to exec in and run certbot and download the certs.

If you're renewing (not getting a new cert) then make sure that the `certbot`
container has the info from the previous time a letsencrypt cert was gotten or
renewed. Use `docker cp` to get the saved tar file back into the container
and untar it if necessary.

```sh
docker cp ~/Downloads/letsencrypt-riffplatform-20181116.tar.gz ssl-stack_certbot.1.joc5p7an6ews92l6yx4bl5onj:/
docker exec -it ssl-stack_certbot.1.joc5p7an6ews92l6yx4bl5onj bash
tar -xvzf letsencrypt-riffplatform-20181116.tar.gz
rm letsencrypt-riffplatform-20181116.tar.gz
certbot certonly --domain beta.riffplatform.com --webroot-path /usr/share/nginx/html
# It doesn't matter but I've been picking the 1st account: ea745093e479@2018-09-04T21:04:31Z (8450)
# Update the Route 53 alias and do it again for another domain if you want
#certbot certonly --domain staging.riffplatform.com --webroot-path /usr/share/nginx/html
# create the tar file w/ the renewed certs and any other updated letsencrypt info
tar -cvzf letsencrypt-riffplatform-NEWDATE.tar.gz /etc/letsencrypt/
exit
docker cp ssl-stack_certbot.1.joc5p7an6ews92l6yx4bl5onj:/letsencrypt-riffplatform-NEWDATE.tar.gz letsencrypt-riffplatform-NEWDATE.tar.gz
docker stack rm ssl-stack
```

----

## Summary

What I did to get my initial letsencrypt certificates was:
1. create an nginx service constrained to run on the swarm manager
2. exec an interactive bash console in that nginx container
3. [install certbot][certbot-install]
4. run certbot webroot pointing at the nginx html root
5. tar the etc/letsencrypt directory and copy the tar file to the nginx root
6. download the tar file
7. untar the letsencrypt files
8. create the docker secrets
9. remove the temp nginx service
10. deploy my real stack w/ my nginx web-server service using the secrets as you've defined here.

[certbot]: <https://certbot.eff.org/docs/intro.html> "Certbot documentation introduction"
[certbot-install]: <https://certbot.eff.org/docs/install.html> "Certbot installation"

## Details

### Create nginx service on manager in the swarm

**Prerequisite**: A docker swarm running in AWS with the domain you want
to create an SSL cert for already pointing at that swarm. And a tunnel created
to a manager node of that swarm so that these commands operate on it.

Use the `ssl-stack.yml` file to deploy an nginx container the docker swarm
the domain points to.
(We use a yml file to make it easier to specify the constraints, namely the
nginx container must run on a manager node so that we can exec into it.

```sh
docker stack deploy --compose-file ssl-stack.yml ssl
```

```console
(venv) mjl@redbaron ~/Projects/riff/riff-docker/web-server $ docker stack deploy --compose-file ssl-stack.yml letsencrypt
Creating network letsencrypt_default
Creating service letsencrypt_letsencrypt
Creating service letsencrypt_visualizer
```

confirm the `ssl` stack `letsencrypt` service is running on the manager you are currently tunneled in to.
```sh
docker ps
```
You should see a running container whose name begins with `ssl_letsencrypt`.

```console
(venv) mjl@redbaron ~/Projects/riff/riff-docker/web-server $ docker ps
CONTAINER ID        IMAGE                                       COMMAND                  CREATED              STATUS              PORTS                         NAMES
ea745093e479        nginx:latest                                "nginx -g 'daemon of…"   About a minute ago   Up About a minute   80/tcp                        ssl_letsencrypt.1.nfda2n1608qj8qrocuuvunxl1
2c59c7a09240        dockersamples/visualizer:stable             "npm start"              About a minute ago   Up About a minute   8080/tcp                      ssl_visualizer.1.2xi20lnme960mcc1id9ffvdpr
879ec3a91327        docker4x/l4controller-aws:18.03.0-ce-aws1   "loadbalancer run --…"   4 hours ago          Up 4 hours                                        l4controller-aws
a9190109f780        docker4x/meta-aws:18.03.0-ce-aws1           "metaserver -iaas_pr…"   4 hours ago          Up 4 hours          172.31.3.197:9024->8080/tcp   meta-aws
45649b47c9c2        docker4x/guide-aws:18.03.0-ce-aws1          "/entry.sh"              4 hours ago          Up 4 hours                                        guide-aws
303062937a6c        docker4x/shell-aws:18.03.0-ce-aws1          "/entry.sh /usr/sbin…"   4 hours ago          Up 4 hours          0.0.0.0:22->22/tcp            shell-aws
```

### Create the letsencrypt certificate on the nginx container and download it

Use `docker exec` to start an interactive bash shell on the ssl nginx container:
```sh
(venv) mjl@redbaron ~/Projects/riff/riff-docker/web-server $ docker exec -it ssl_letsencrypt.1.nfda2n1608qj8qrocuuvunxl1 bash
```

Update the apt repository list w/ the backports repository and install certbot,
then run certbot to get the letsencrypt certificate:
```sh
echo 'deb http://ftp.debian.org/debian stretch-backports main' >> /etc/apt/sources.list
apt-get update
apt-get install certbot -t stretch-backports
certbot certonly --agree-tos --email admin@rifflearning.com --webroot --webroot-path /usr/share/nginx/html --domain staging.riffplatform.com
```

```console
root@ea745093e479:/# certbot certonly --agree-tos --email admin@rifflearning.com --webroot --webroot-path /usr/share/nginx/html --domain staging.riffplatform.com
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Plugins selected: Authenticator webroot, Installer None

-------------------------------------------------------------------------------
Would you be willing to share your email address with the Electronic Frontier
Foundation, a founding partner of the Let's Encrypt project and the non-profit
organization that develops Certbot? We'd like to send you email about our work
encrypting the web, EFF news, campaigns, and ways to support digital freedom.
-------------------------------------------------------------------------------
(Y)es/(N)o: y
Obtaining a new certificate
Performing the following challenges:
http-01 challenge for staging.riffplatform.com
Using the webroot path /usr/share/nginx/html for all unmatched domains.
Waiting for verification...
Cleaning up challenges

IMPORTANT NOTES:
 - Congratulations! Your certificate and chain have been saved at:
   /etc/letsencrypt/live/staging.riffplatform.com/fullchain.pem
   Your key file has been saved at:
   /etc/letsencrypt/live/staging.riffplatform.com/privkey.pem
   Your cert will expire on 2018-12-03. To obtain a new or tweaked
   version of this certificate in the future, simply run certbot
   again. To non-interactively renew *all* of your certificates, run
   "certbot renew"
 - Your account credentials have been saved in your Certbot
   configuration directory at /etc/letsencrypt. You should make a
   secure backup of this folder now. This configuration directory will
   also contain certificates and private keys obtained by Certbot so
   making regular backups of this folder is ideal.
 - If you like Certbot, please consider supporting our work by:

   Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
   Donating to EFF:                    https://eff.org/donate-le

```

Create an archive of the letsencrypt certificate files created in
the nginx webroot directory:
```sh
cd /usr/share/nginx/html/
tar cvzf letsencrypt.tar.gz /etc/letsencrypt/
exit
```

Now download  http://staging.riffplatform.com/letsencrypt.tar.gz

Get rid of the ssl docker stack:
```sh
docker stack rm ssl
```

Unpack the tar file so you can create the docker secrets from it:

```sh
docker secret create staging.riffplatform.com.key.1 web-server/letsencrypt/archive/staging.riffplatform.com/privkey1.pem
docker secret create staging.riffplatform.com.crt.1 web-server/letsencrypt/archive/staging.riffplatform.com/fullchain1.pem
```

If you're creating new ssl certs, you're probably setting up a new swarm so don't forget to create
the configs:

```sh
docker config create riff-rtc.local-production.yml.3 config/riff-rtc.local-production.yml.3
docker config create signalmaster.local-production.yml.1 config/signalmaster.local-production.yml.1
```

## Appendix

### ssl-stack.yml

The visualizer service is included just so you can both test that the domain
is correctly pointing to the swarm (e.g.by using http://staging.riffplatform.com:8080)
and you can see the containers currently running on the swarm.
```yaml
---
version: '3'
services:
  letsencrypt:
    image: nginx:latest
    ports:
      - '80:80'
      - '443:443'
    deploy:
      placement:
        constraints: [node.role == manager]
  visualizer:
    image: dockersamples/visualizer:stable
    ports:
      - "8080:8080"
    stop_grace_period: 1m30s
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
    deploy:
      placement:
        constraints: [node.role == manager]


```
