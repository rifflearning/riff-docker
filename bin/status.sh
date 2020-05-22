#! /usr/bin/env bash
# show the status of what's on this AWS riff platform instance

cd ~/riff/riff-docker
echo "--- riff-docker ---"
git show --oneline --no-patch

echo
echo "--- docker ---"
echo "- - - IMAGES - - -"
docker images

echo
echo "- - - STACK (pfm-stk) Running Processes - - -"
FORMAT="table {{.Name}}\t{{.CurrentState}}\t{{.Image}}"
FILTER="desired-state=running"
docker stack ps --format "$FORMAT" --filter="$FILTER" pfm-stk

# TODO:
# It might be useful to see if there are any shutdown tasks without a later running task
# for the same name. This needs some testing when deploying the stack is failing to see
# how to produce useful information including the Error
# FILTER="desired-state=shutdown"
# FORMAT="table {{.Name}}\t{{.CurrentState}} ({{.Error}})\t{{.Image}}"
