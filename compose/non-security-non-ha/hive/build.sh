#!/usr/bin/env bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
set -e
cd $DIR
mkdir -p $DIR/tmp/hive
tar -xf $HIVE_PACKAGE -C $DIR/tmp/hive --strip-components=1

mkdir -p $DIR/tmp/derby
tar -xf $DERBY_PACKAGE -C $DIR/tmp/derby --strip-components=1

cp $DIR/tmp/derby/lib/derbyclient.jar $DIR/tmp/hive/lib
cp $DIR/tmp/derby/lib/derbytools.jar $DIR/tmp/hive/lib
cp $DIR/utils/*.sh $DIR/tmp/hive/bin
chmod +x $DIR/tmp/hive/bin/initAndStartMetastore.sh

cp -r $DIR/hive-conf/* $DIR/tmp/hive/conf
BASE_IMAGE_VERSION=${HADOOP_VERSION}
BASE_IMAGE_NAME=hadoop
TARGET_IMAGE_NAME="hive-${USER_NAME}:$HIVE_VERSION"

if [ "${EMBED_IN_SINGLE_CONTAINER}" == "true" ]; then
   # In case of single container hive needs both derby and hadoop
   BASE_IMAGE_VERSION="${DERBY_VERSION}-${HADOOP_VERSION}"
   BASE_IMAGE_NAME="derby-hadoop"
   TARGET_IMAGE_NAME="hive-hadoop-${USER_NAME}:${HIVE_VERSION}-${HADOOP_VERSION}"

   #In case of single container, use localhost as derby hostname
   cp -r $DIR/hive-conf/hive-site-singlecontainer.xml $DIR/tmp/hive/conf/hive-site.xml
fi


docker build --build-arg IMAGE_VERSION=${BASE_IMAGE_VERSION} \
   --build-arg USER_NAME=${USER_NAME} \
   --build-arg BASE_IMAGE=${BASE_IMAGE_NAME} \
   -t $TARGET_IMAGE_NAME -f $DIR/Dockerfile $DIR/tmp
rm -rf $DIR/tmp
