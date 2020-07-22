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
cp $DIR/utils/initAndStartMetastore.sh $DIR/tmp/hive/bin
chmod +x $DIR/tmp/hive/bin/initAndStartMetastore.sh

cp -r $DIR/hive-conf/* $DIR/tmp/hive/conf

docker build --build-arg HADOOP_VERSION=$HADOOP_VERSION \
   --build-arg USER_NAME=${USER_NAME} \
   -t hive-${USER_NAME}:$HIVE_VERSION -f $DIR/Dockerfile $DIR/tmp
rm -rf $DIR/tmp
