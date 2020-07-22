#!/usr/bin/env bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
set -e

source $DIR/config

COMPONENTS=(base
 hadoop
 derby
 hive)


for comp in "${COMPONENTS[@]}" ; do
    cd $DIR/$comp;
    bash -x $DIR/$comp/build.sh
    cd $DIR;
done