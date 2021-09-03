#!/usr/bin/env bash
cd $DERBY_HOME/data
startNetworkServer -h "0.0.0.0" &
#Wait for 3 seconds to allow derby to startup
sleep 3