#!/usr/bin/env bash

#Start the HDFS
hdfs --daemon start namenode
hdfs --daemon start datanode
hdfs --daemon start secondarynamenode

#Start the derby DB
start-derby.sh

#Init, if not already, and start Hive Metastore and HiveService2
initAndStartMetastore.sh