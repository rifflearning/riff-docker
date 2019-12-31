#! /usr/bin/env sh

# aws setupfiles are for development and shouldn't be used in production
# production should use docker secret files
ln -s /setupfiles/aws/config /run/secrets/aws_config
ln -s /setupfiles/aws/credentials /run/secrets/aws_credentials

# install mongodb-tools for mongodump to use for backing up mongo databases
apk update
apk add mongodb-tools

# put the cronjob in place to run every 15 minutes
ln -s /setupfiles/backupjob /etc/periodic/15min/backupjob

cd ~
ln -s /setupfiles/.profile .profile
ln -s /setupfiles/entrypoint.sh entrypoint.sh

# link AWS credentials needed to write to S3
mkdir .aws
ln -s /run/secrets/aws_config .aws/config
ln -s /run/secrets/aws_credentials .aws/credentials

mkdir backup
cd backup
pip install boto3
