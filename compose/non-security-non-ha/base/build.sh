#!/usr/bin/env bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR
set -e
docker build --build-arg USER_ID=${USER_ID} \
  --build-arg USER_NAME=${USER_NAME} \
  --build-arg GROUP_ID=${GROUP_ID} \
  -t hadoop-runner-${USER_NAME}:base .