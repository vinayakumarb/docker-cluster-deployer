#!/usr/bin/env bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
set -e
cd $DIR
mkdir -p $DIR/tmp/derby;
tar -xf $DERBY_PACKAGE -C $DIR/tmp/derby --strip-components=1

cp $DIR/scripts/start-derby.sh $DIR/tmp/derby/bin
chmod 755 $DIR/tmp/derby/bin/start-derby.sh

BASE_IMAGE_VERSION="base"
BASE_IMAGE_NAME="hadoop-runner"
TARGET_IMAGE_NAME="derby-${USER_NAME}:${DERBY_VERSION}"

if [ "${EMBED_IN_SINGLE_CONTAINER}" == "true" ]; then
   # In case of single container hive needs both derby and hadoop
   BASE_IMAGE_VERSION="${HADOOP_VERSION}"
   BASE_IMAGE_NAME="hadoop"
   TARGET_IMAGE_NAME="derby-hadoop-${USER_NAME}:${DERBY_VERSION}-${HADOOP_VERSION}"
fi

docker build  --build-arg USER_NAME=${USER_NAME} \
   --build-arg IMAGE_VERSION=${BASE_IMAGE_VERSION} \
   --build-arg BASE_IMAGE=${BASE_IMAGE_NAME} \
  -t $TARGET_IMAGE_NAME -f $DIR/Dockerfile $DIR/tmp
rm -rf $DIR/tmp
