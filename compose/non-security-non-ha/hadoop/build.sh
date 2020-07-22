#!/usr/bin/env bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
set -e
cd $DIR
rm -rf tmp && mkdir -p $DIR/tmp/hadoop;
tar -xf $HADOOP_PACKAGE -C $DIR/tmp/hadoop --strip-components=1
cp -r $DIR/hadoop-conf/* $DIR/tmp/hadoop/etc/hadoop
rm -rf $DIR/tmp/hadoop/share/doc

docker build --build-arg USER_NAME=${USER_NAME} \
  -t hadoop-${USER_NAME}:$HADOOP_VERSION -f $DIR/Dockerfile $DIR/tmp
rm -rf $DIR/tmp