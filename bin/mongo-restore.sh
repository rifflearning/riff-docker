#!/bin/sh
# currently this is more example of the commands to use than a runnable script

STACK_NAME=riff-docker
MONGO_SERVICE=mongo-server
MONGO_CONTAINER=${STACK_NAME}_${MONGO_SERVICE}_1
DATABASE_NAME="riff-test"
ARCHIVE_NAME=$1

docker cp ~/tmp/${ARCHIVE_NAME} ${MONGO_CONTAINER}:/data/
docker exec -t ${MONGO_CONTAINER} mongorestore --db=${DATABASE_NAME} --gzip --archive=/data/${ARCHIVE_NAME}
docker exec -t ${MONGO_CONTAINER} rm /data/${ARCHIVE_NAME}
