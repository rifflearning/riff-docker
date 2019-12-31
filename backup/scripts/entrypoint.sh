#! /usr/bin/env sh

# set syslog messages to go to /var/log/messages
syslogd

# run cron in the foreground, so the container runs until cron is stopped
crond -l 8 -f
