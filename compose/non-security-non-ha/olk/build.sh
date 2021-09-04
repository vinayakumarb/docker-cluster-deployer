#!/usr/bin/env bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
set -e
cd $DIR
mkdir -p $DIR/tmp/olk
tar -xf $OLK_PACKAGE -C $DIR/tmp/olk --strip-components=1

cp -r $DIR/etc $DIR/tmp/olk/etc
mkdir -p $DIR/tmp/olk/etc/dynamic/catalog

BASE_IMAGE_VERSION=${HADOOP_VERSION}
BASE_IMAGE_NAME=hadoop
TARGET_IMAGE_NAME="olk-${USER_NAME}:$OLK_VERSION"

if [ "${EMBED_IN_SINGLE_CONTAINER}" == "true" ]; then
   # In case of single container namenode's hostname and hive's hostname is different. provide them via jvm.config
   cp $DIR/etc/jvm-singlecontainer.config $DIR/tmp/olk/etc/jvm.config
fi

docker build --build-arg IMAGE_VERSION=${BASE_IMAGE_VERSION} \
   --build-arg USER_NAME=${USER_NAME} \
   --build-arg BASE_IMAGE=${BASE_IMAGE_NAME} \
   -t $TARGET_IMAGE_NAME -f $DIR/Dockerfile $DIR/tmp

rm -rf $DIR/tmp
