#!/usr/bin/env bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
set -e
cp $HADOOP_HOME/share/hadoop/client/*.jar $HIVE_HOME/lib
if ![ -f /tmp/${USER}/HIVE_INITIALIZED ]; then
  #Init the schema
  schematool -dbType derby -initSchema
  #Create the basic dirs
  hdfs dfs -mkdir -p /user/hive/warehouse
  touch /tmp/${USER}/HIVE_INITIALIZED;
fi
#Start metastore
nohup hive --service metastore > /tmp/${USER}/hivemeta.log &
hive --service hiveserver2
