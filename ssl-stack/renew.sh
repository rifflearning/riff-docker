#! /usr/bin/env bash
#
# Restore saved letsencrypt archive, run certbot and copy updated letsencrypt archive from container

CB_CNTR=$(docker ps --filter="volume=ssl-stack_letsencrypt-data" --filter="status=running" --format={{.Names}})

TIMESTAMP=$(date +'%Y%m%d%H%M%S')
ARCHIVE_PATH="../config/secret/"
ARCHIVE_NAME=$1
NEW_ARCHIVE_NAME=letsencrypt-riffsites-${TIMESTAMP}.tar.gz
DOMAIN=$2

if [[ ! -f "${ARCHIVE_PATH}${ARCHIVE_NAME}" ]]; then
    echo "The archive of the current letsencryt settings does not exist."
    echo "It is expected to be one of these files:"
    pushd "${ARCHIVE_PATH}" > /dev/null
    ls -1 letsencrypt-riffsites-*.tar.gz
    popd > /dev/null
    echo
    echo "Syntax:"
    echo "$0 <archive file name> <fq domain>"
    exit 1
fi

echo "The following will be used for the renewal:"
echo "  Certbot container: $CB_CNTR"
echo "       Archive file: ${ARCHIVE_PATH}${ARCHIVE_NAME}"
echo "             Domain: $DOMAIN"
read -rsp $'Press any key to continue or Ctrl-C to abort\n' -n1 key

echo
docker cp ${ARCHIVE_PATH}${ARCHIVE_NAME} $CB_CNTR:/
docker exec $CB_CNTR tar -xvzf /${ARCHIVE_NAME}
docker exec $CB_CNTR rm /${ARCHIVE_NAME}
echo "run: 'certbot certonly --domain $2 --webroot --webroot-path /usr/share/nginx/html'"

docker exec -it $CB_CNTR bash

docker exec $CB_CNTR tar -cvzf /${NEW_ARCHIVE_NAME} /etc/letsencrypt/
docker cp  $CB_CNTR:/${NEW_ARCHIVE_NAME} ${ARCHIVE_PATH}
docker exec $CB_CNTR rm /${NEW_ARCHIVE_NAME}
