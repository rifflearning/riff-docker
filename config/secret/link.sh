#! /usr/bin/env bash

if [ $# -ne 3 ]
  then
    echo "Syntax: ./link.sh <3rd level domain name> <edu | platform | remote> <cert ver number>"
    echo "ex: ./link.sh staging edu 5"
    echo
    exit 1
fi

RIFF_HOST=$1.riff${2}.com
CERT_VER=$3

ln -s ./etc/letsencrypt/archive/${RIFF_HOST}/fullchain${CERT_VER}.pem ${RIFF_HOST}.crt.${CERT_VER}
ln -s ./etc/letsencrypt/archive/${RIFF_HOST}/privkey${CERT_VER}.pem ${RIFF_HOST}.key.${CERT_VER}

# show information about the certificate
# from: https://www.shellhacks.com/decode-ssl-certificate/
openssl x509 -in ${RIFF_HOST}.crt.${CERT_VER} -issuer -noout -subject -dates
