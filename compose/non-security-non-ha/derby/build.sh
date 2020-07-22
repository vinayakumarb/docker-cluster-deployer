#!/usr/bin/env bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
set -e
cd $DIR
mkdir -p $DIR/tmp/derby;
tar -xf $DERBY_PACKAGE -C $DIR/tmp/derby --strip-components=1

docker build  --build-arg USER_NAME=${USER_NAME} \
  -t derby-${USER_NAME}:$DERBY_VERSION -f $DIR/Dockerfile $DIR/tmp
rm -rf $DIR/tmp
