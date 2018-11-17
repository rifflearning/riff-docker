#!/bin/sh
# currently this is more example of the commands to use than a runnable script

STACK_NAME=riff-docker
MONGO_SERVICE=mongo-server
MONGO_CONTAINER=${STACK_NAME}_${MONGO_SERVICE}_1
DATABASE_NAME="riff-test"
TIMESTAMP=$(date +'%Y%m%d%H%M%S')
ARCHIVE_NAME=mongodb_${DATABASE_NAME}.backup-${TIMESTAMP}.gz

docker exec -t ${MONGO_CONTAINER} mongodump --db=${DATABASE_NAME} --gzip --archive=/data/${ARCHIVE_NAME}
docker exec -t ${MONGO_CONTAINER} ls -lrt /data
docker cp ${MONGO_CONTAINER}:/data/${ARCHIVE_NAME} ~/tmp
