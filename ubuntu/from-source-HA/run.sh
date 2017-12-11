#!/usr/bin/env bash
set -e

HADOOP_SRC_HOME=/usr1/code/hadoop/branch-2
HADOOP_VERSION=2.8.3
ZK_INSTALLER_PATH=/usr1/code/hadoop/rel/zookeeper-3.4.11.tar.gz

HADOOP_MAJOR_VERSION=$(echo $HADOOP_VERSION|cut -d. -f1)

let N=3

# The hadoop home in the docker containers
HADOOP_HOME=/hadoop
ZK_HOME=/zk

function usage() {
    echo "Usage: ./run.sh [--rebuild] [--nodes=N]"
    echo
    echo "--rebuild    Rebuild hadoop if in hadoop mode; else reuild spark"
    echo "--nodes      Specify the number of total nodes"
}

# @Return the hadoop distribution package for deployment
function hadoop_target() {
    echo $(find $HADOOP_SRC_HOME/hadoop-dist/target/ -type d -name hadoop-$HADOOP_VERSION)
}

function build_hadoop() {
    if [[ $REBUILD -eq 1 || "$(docker images -q caochong-hadoop)" == "" ]]; then
        echo "Building Hadoop...."
        #rebuild the base image if not exist
        if [[ "$(docker images -q caochong-base)" == "" ]]; then
            echo "Building Docker...."
            docker build -t caochong-base .
        fi
        rm -rf tmp
        mkdir tmp

        # Prepare hadoop packages and configuration files
        #mvn -f $HADOOP_SRC_HOME clean package -Pnative -DskipTests -Dtar -Pdist -Dmaven.javadoc.skip=true -Dsource.skip=true -DskipShade || exit 1
        HADOOP_TARGET_SNAPSHOT=$(hadoop_target)
        cp -r $HADOOP_TARGET_SNAPSHOT tmp/hadoop
        cp hadoopconf/* tmp/hadoop/etc/hadoop/

        tar -xf $ZK_INSTALLER_PATH -C tmp
        cp zkconf/zoo.cfg tmp/zookeeper-3.4.11/conf
        mv tmp/zookeeper-3.4.11 tmp/zk

        # Generate docker file for hadoop
cat > tmp/Dockerfile << EOF
        FROM caochong-base

        ENV HADOOP_HOME $HADOOP_HOME
        ENV ZK_HOME $ZK_HOME
        ENV HDFS_ZKFC_USER root
        ENV HDFS_JOURNALNODE_USER root
        ENV HDFS_NAMENODE_USER root
        ENV HDFS_DATANODE_USER root
        ENV HDFS_SECONDARYNAMENODE_USER root
        ENV YARN_RESOURCEMANAGER_USER root
        ENV YARN_NODEMANAGER_USER root
        ENV HADOOP_IDENT_STRING root
        ADD hadoop $HADOOP_HOME
        ADD zk $ZK_HOME
        ENV PATH "\$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin"

        EXPOSE 22 2181 9820 8045 8088 9870 9864 9866 9867
EOF
        echo "Building image for hadoop"
        docker rmi -f caochong-hadoop
        docker build -t caochong-hadoop tmp

        # Cleanup
        rm -rf tmp
    fi
}

# Parse and validatet the command line arguments
function parse_arguments() {
    while [ "$1" != "" ]; do
        PARAM=`echo $1 | awk -F= '{print $1}'`
        VALUE=`echo $1 | awk -F= '{print $2}'`
        case $PARAM in
            -h | --help)
                usage
                exit
                ;;
            --rebuild)
                REBUILD=1
                ;;
            --nodes)
                N=$VALUE
                ;;
            *)
                echo "ERROR: unknown parameter \"$PARAM\""
                usage
                exit 1
                ;;
        esac
        shift
    done
}

parse_arguments $@

build_hadoop

if [[ "$(docker network ls --filter name=caochong|wc -l)" == "1" ]];then
  docker network create caochong 2> /dev/null 
fi

# remove the outdated master
runningContainers=$(docker ps -a -q -f "name=caochong")
if [[ "$runningContainers" != "" ]];then
  docker rm -f $(docker ps -a -q -f "name=caochong") 2>&1 > /dev/null
fi
rm -rf hosts
# launch master container
master_ids=();
for i in $(seq 2);
do
    port_addition=$(expr $i \* 10000)
    nn_http_port=$(expr $port_addition + 9870)
    dn_http_port=$(expr $port_addition + 9864)
    rm_http_port=$(expr $port_addition + 8088)
    container_id=$(docker run -p $nn_http_port:9870 -p $dn_http_port:9864 -p $rm_http_port:8088 -d --net caochong --name caochong-master-$i -h master$i --network-alias=master$i caochong-hadoop)
    master_ids[$i]=${container_id:0:12};
    echo "master$i" >> hosts
done
for i in $(seq $((N-2)));
do
    j=$(expr $i + 2 )
    port_addition=$(expr $j \* 10000)
    dn_http_port=$(expr $port_addition + 9864)
    container_id=$(docker run -p $dn_http_port:9864 -d --net caochong --name caochong-slave-$i -h slave$i --network-alias=slave$i caochong-hadoop)
    echo "slave$i" >> hosts
done

# Copy the workers file to the master container
docker cp hosts ${master_ids[1]}:$HADOOP_HOME/etc/hadoop/workers
docker cp hosts ${master_ids[1]}:$HADOOP_HOME/etc/hadoop/slaves
docker cp hosts ${master_ids[2]}:$HADOOP_HOME/etc/hadoop/workers
docker cp hosts ${master_ids[2]}:$HADOOP_HOME/etc/hadoop/slaves

#Start the zookeeper
docker exec -it ${master_ids[1]} $ZK_HOME/bin/zkServer.sh start
sleep 2
#Format ZKFC
docker exec -it ${master_ids[1]} $HADOOP_HOME/bin/hdfs zkfc -formatZK
docker exec -it ${master_ids[1]} rm -f /tmp/hadoop-root-zkfc.pid
#Start journal nodes
if [ $HADOOP_MAJOR_VERSION == 3 ];then
    docker exec -it ${master_ids[1]} "${HADOOP_HOME}/bin/hdfs" \
        --workers \
        --hostnames "master1 master2 slave1" \
        --daemon start \
        journalnode
else
    docker exec -it ${master_ids[1]} /bin/bash "${HADOOP_HOME}/sbin/hadoop-daemons.sh" \
        start \
        journalnode
fi
sleep 3
#Format the Active namenode and start it
docker exec -it ${master_ids[1]} "${HADOOP_HOME}/bin/hdfs" \
    namenode -format -force
docker exec -it ${master_ids[1]} rm -f /tmp/hadoop-root-namenode.pid
#Workaround for the Docker exec issue. Docker exec,  on exit, kills the nohup processes launched by it. 

startHadoopDaemon(){
    node=$1
    process=$2
    hostname=$3
    if [ $HADOOP_MAJOR_VERSION == 3 ];then
        docker exec -it $1 /bin/bash -c 'export HADOOP_IDENT_STRING=root;nohup ${HADOOP_HOME}/bin/hdfs \
            --daemon start '$process' & > output & sleep 3'
    else
        docker exec -it $1 /bin/bash -c 'export HADOOP_IDENT_STRING=root;nohup ${HADOOP_HOME}/sbin/hadoop-daemon.sh \
             start '$process' & > output & sleep 3'
    fi
    docker exec -it $1 tail ${HADOOP_HOME}/logs/hadoop-root-namenode-$hostname.log
}

startHadoopDaemon ${master_ids[1]} namenode master1
startHadoopDaemon ${master_ids[1]} zkfc master1

#Bootstrap the standby namenode and start it
docker exec -it ${master_ids[2]} "${HADOOP_HOME}/bin/hdfs" \
    namenode -bootstrapStandby
docker exec -it ${master_ids[2]} rm -f /tmp/hadoop-root-namenode.pid

startHadoopDaemon ${master_ids[2]} namenode master2
startHadoopDaemon ${master_ids[2]} zkfc master2

# Start remaining hdfs and yarn services
docker exec -it ${master_ids[1]} $HADOOP_HOME/sbin/start-dfs.sh
docker exec -it ${master_ids[1]} $HADOOP_HOME/sbin/start-yarn.sh

# Connect to the master node
docker exec -it ${master_ids[1]} /bin/bash
