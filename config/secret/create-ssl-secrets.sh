#! /usr/bin/env bash

if [ $# -lt 1 ]
  then
    echo "Syntax: $0 files to add as secrets"
    echo "ex: $0 staging.*edu*"
    echo
    exit 1
fi

for f ; do
    echo docker secret create $f{,}
    docker secret create $f{,}
done

docker secret ls
