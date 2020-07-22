#!/usr/bin/env bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
set -e
cp $HADOOP_HOME/share/hadoop/client/*.jar $HIVE_HOME/lib
#Init the schema
schematool -dbType derby -initSchema
#Create the basic dirs
hdfs dfs -mkdir -p /user/hive/warehouse
#Start metastore
hive --service metastore