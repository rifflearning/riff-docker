The following commands for creating a self-signed certificate were found on Digital Ocean's
[How To Create a Self-Signed SSL Certificate for Nginx on Debian 8][do_tut_ssl].

[do_tut_ssl]: <https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-nginx-on-debian-8>

```sh
$ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ssl/private/nginx-selfsigned.key -out ssl/certs/nginx-selfsigned.crt
Generating a 2048 bit RSA private key
.........+++
.................................+++
writing new private key to 'ssl/private/nginx-selfsigned.key'
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [AU]:US
State or Province Name (full name) [Some-State]:Massachusetts
Locality Name (eg, city) []:Boston
Organization Name (eg, company) [Internet Widgits Pty Ltd]:Riff Learning
Organizational Unit Name (eg, section) []:
Common Name (e.g. server FQDN or YOUR name) []:127.0.0.1
Email Address []:admin@rifflearning.com

$ openssl dhparam -out ssl/certs/dhparam.pem 2048     
Generating DH parameters, 2048 bit long safe prime, generator 2
```
