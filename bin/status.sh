#! /usr/bin/env bash
# show the status of what's on this AWS riff platform instance

cd ~/riff/riff-docker
echo "--- riff-docker ---"
git show --oneline --no-patch

echo
echo "--- docker ---"
echo "- - - IMAGES - - -"
docker images

FORMAT="table {{.Name}}\t{{.CurrentState}}\t{{.Image}}"
FILTER="desired-state=running"
STACKS=( support-stack ssl-stack pfm-stk )
for stk in "${STACKS[@]}"
do
    # Only report on stack processes if some are found
    if docker stack ps --filter="$FILTER" $stk > /dev/null 2>&1
    then
        echo
        echo "- - - STACK ($stk) Running Processes - - -"
        docker stack ps --filter="$FILTER" --format "$FORMAT" $stk
    fi
done

# TODO:
# It might be useful to see if there are any shutdown tasks without a later running task
# for the same name. This needs some testing when deploying the stack is failing to see
# how to produce useful information including the Error
# FILTER="desired-state=shutdown"
# FORMAT="table {{.Name}}\t{{.CurrentState}} ({{.Error}})\t{{.Image}}"
#
# 1 possible error condition is missing node constraints where the docker inspect of the
# task looks like:
#
# $ docker stack ps support-stack
# ID                  NAME                         IMAGE                             NODE                DESIRED STATE       CURRENT STATE            ERROR                              PORTS
# x6atvbxc0lum        support-stack_visualizer.1   dockersamples/visualizer:stable   ip-172-31-13-66     Running             Running 5 seconds ago
# g8qzz94t4k6w        support-stack_registry.1     registry:2                                            Running             Pending 11 seconds ago   "no suitable node (scheduling …"
#
# $ docker inspect g8qzz94t4k6w
# [
#     {
#         "ID": "g8qzz94t4k6wu3koidkrvwtpe",
#         ...
#         "Status": {
#             "Timestamp": "2020-05-27T16:58:56.306225927Z",
#             "State": "pending",
#             "Message": "pending task scheduling",
#             "Err": "no suitable node (scheduling constraints not satisfied on 1 node)",
#             "PortStatus": {}
#         },
#         "DesiredState": "running",
#         ...
#     }
# ]
