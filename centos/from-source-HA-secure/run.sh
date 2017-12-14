#!/usr/bin/env bash
set -e
SCRIPT_NAME=$(basename $BASH_SOURCE)
DIR=$(dirname $BASH_SOURCE);
DIR=$(cd $DIR && pwd);

HADOOP_SRC_HOME=/usr1/install/hadoop-3.0.0-src
HADOOP_VERSION=3.0.0

ZK_INSTALLER_PATH=/usr1/code/hadoop/rel/zookeeper-3.4.11.tar.gz

HADOOP_MAJOR_VERSION=$(echo $HADOOP_VERSION|cut -d. -f1)

REBUILD=0
let N=3
SKIP_MVN=false
REGENERATE_CA=false;

# The hadoop home in the docker containers
HADOOP_HOME=/hadoop
ZK_HOME=/zk
ZOO_LOG_DIR=/var/log/zk
HADOOP_LOG_DIR=/var/log/hadoop/hdfs
YARN_LOG_DIR=/var/log/hadoop/yarn

function usage() {
    echo "Usage: ./run.sh [--rebuild] [--skipMvn] [--regenerateCA] [--nodes=N]"
    echo
    echo "--rebuild    Rebuild hadoop if in hadoop mode; else reuild spark"
    echo "--nodes      Specify the number of total nodes"
}

# @Return the hadoop distribution package for deployment
function hadoop_target() {
    echo $(find $HADOOP_SRC_HOME/hadoop-dist/target/ -type d -name 'hadoop-'$HADOOP_VERSION)
}

function build_hadoop() {
    if [[ $REBUILD -eq 1 || "$(docker images -q hadoop-centos-secure)" == "" ]]; then
        echo "Building Hadoop...."
        #rebuild the base image if not exist
        if [[ "$(docker images -q hadoop-centos-base)" == "" ]]; then
            echo "Building Docker...."
            docker build -t hadoop-centos-base .
        fi
        rm -rf tmp
        mkdir tmp

        #Stop running containers with the name
        docker rm -f $(docker ps -a -q -f "ancestor=hadoop-centos-secure") || true  2>&1  > /dev/null

        # Prepare hadoop packages and configuration files
        if [ "$SKIP_MVN" == "false" ]; then
          cur=$(PWD)
          cd $HADOOP_SRC_HOME && mvn clean package -Pnative -DskipTests -Dtar -Pdist -Dmaven.javadoc.skip=true -Dsource.skip=true -DskipShade || exit 1
          cd $cur;
        fi
        HADOOP_TARGET_SNAPSHOT=$(hadoop_target)
        cp -r $HADOOP_TARGET_SNAPSHOT tmp/hadoop
        cp hadoopconf/* tmp/hadoop/etc/hadoop/
        cp -r ./scripts tmp

        tar -xf $ZK_INSTALLER_PATH -C tmp
        cp zkconf/zoo.cfg tmp/zookeeper-3.4.11/conf
        mv tmp/zookeeper-3.4.11 tmp/zk

        # Generate docker file for hadoop
cat > tmp/Dockerfile << EOF
        FROM hadoop-centos-base

        #ZK related environments
        ENV ZK_HOME $ZK_HOME
        ENV ZOO_LOG_DIR $ZOO_LOG_DIR
        ENV ZOO_LOG4J_PROP INFO,ROLLINGFILE

        #HDFS Related env
        ENV HADOOP_HOME $HADOOP_HOME
        ENV HADOOP_LOG_DIR $HADOOP_LOG_DIR
        ENV HDFS_ZKFC_USER hdfs
        ENV HDFS_JOURNALNODE_USER hdfs
        ENV HDFS_NAMENODE_USER hdfs
        ENV HDFS_DATANODE_USER hdfs
        ENV HDFS_SECONDARYNAMENODE_USER hdfs
        #YARN env
        ENV YARN_LOG_DIR $YARN_LOG_DIR
        ENV YARN_RESOURCEMANAGER_USER yarn
        ENV YARN_PROXYSERVER_USER yarn
        ENV YARN_NODEMANAGER_USER yarn

        ADD hadoop $HADOOP_HOME

        ADD zk $ZK_HOME
        ADD scripts /root/scripts
        ENV PATH "\$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin"

        #Create users
        RUN /bin/bash /root/scripts/install.sh setupusers "--group=hadoop" "--users=zk,hdfs,mapred,yarn"

        RUN chown -R zk:hadoop $ZK_HOME
        RUN chown -R hdfs:hadoop $HADOOP_HOME

        #Create log directories and change ownership
        RUN mkdir -p $ZOO_LOG_DIR
        RUN chown -R zk:hadoop $ZOO_LOG_DIR
        RUN chmod -R 775 $ZOO_LOG_DIR
        RUN mkdir -p $HADOOP_LOG_DIR
        RUN chown -R hdfs:hadoop $HADOOP_LOG_DIR
        RUN chmod -R 775 $HADOOP_LOG_DIR
        RUN mkdir -p $YARN_LOG_DIR
        RUN chown -R yarn:hadoop $YARN_LOG_DIR
        RUN chmod -R 775 $YARN_LOG_DIR

        #Create local dirs for data
        RUN mkdir -p /data/hdfs/name
        RUN chown -R hdfs:hadoop /data/hdfs/name
        RUN chmod -R 700 /data/hdfs/name

        RUN mkdir -p /data/hdfs/data
        RUN chown -R hdfs:hadoop /data/hdfs/data
        RUN chmod -R 700 /data/hdfs/data

        RUN mkdir -p /data/hdfs/journal
        RUN chown -R hdfs:hadoop /data/hdfs/journal
        RUN chmod -R 700 /data/hdfs/journal

        RUN mkdir -p /data/yarn/nm/localdir
        RUN mkdir -p /data/yarn/nm/logsdir
        RUN chown -R yarn:hadoop /data/yarn
        RUN chmod -R 755 /data/yarn

        RUN chown root:hadoop $HADOOP_HOME/bin/container-executor
        RUN chmod 6050 $HADOOP_HOME/bin/container-executor

        RUN chown root:hadoop $HADOOP_HOME/etc/hadoop/container-executor.cfg
        RUN chmod 0400 $HADOOP_HOME/etc/hadoop/container-executor.cfg

        EXPOSE 22 2181 9820 8045 8088 8090 8091 9870 9871 9864 9865 9866 9867 
EOF
        echo "Building image for hadoop"
        docker rmi -f hadoop-centos-secure
        docker build -t hadoop-centos-secure tmp

        # Cleanup
        rm -rf tmp
    fi
}

function regenerate_ca(){
    if ! [ -f $DIR/scripts/ssl/ca.cert ] || [ "$REGENERATE_CA" == "true" ] ; then
        openssl req -nodes -newkey rsa:2048  -x509 -keyout $DIR/scripts/ssl/ca.key -out $DIR/scripts/ssl/ca.cert -subj "/C=IN/ST=Karnataka/L=Bengaluru/O=Apache Software Foundation/OU=Apache Hadoop/CN=www.people.apache.org/emailAddress=vinayakumarb@apache.org"
    fi
}

# Parse and validatet the command line arguments
function parse_arguments() {
    while [ "$1" != "" ]; do
        PARAM=$(echo $1 | awk -F= '{print $1}')
        VALUE=$(echo $1 | awk -F= '{print $2}')
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
             --skipMvn)
                SKIP_MVN=true
                ;;
             --regenerateCA)
                REGENERATE_CA=true
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

regenerate_ca

if [[ "$(docker network ls --filter name=hadoopsecure.com|wc -l)" == "1" ]];then
  docker network create hadoopsecure.com 2> /dev/null 
fi

# remove the outdated master
runningContainers=$(docker ps -a -q -f "name=vinay-hadoop")
if [[ "$runningContainers" != "" ]];then
  docker rm -f $(docker ps -a -q -f "name=vinay-hadoop") 2>&1 > /dev/null
fi
rm -rf hosts

# launch master container
containerIds=();
for i in $(seq 2);
do
    port_addition=$(expr $i \* 10000)
    nn_http_port=$(expr $port_addition + 9870)
    nn_https_port=$(expr $port_addition + 9871)
    dn_http_port=$(expr $port_addition + 9864)
    dn_https_port=$(expr $port_addition + 9865)
    rm_http_port=$(expr $port_addition + 8088)
    rm_https_port=$(expr $port_addition + 8090)
    container_id=$(docker run -p $nn_http_port:9870 -p $nn_https_port:9871 -p $dn_http_port:9864 -p $dn_https_port:9865 -p $rm_http_port:8088 -p $rm_https_port:8090 -d --net hadoopsecure.com --name vinay-hadoop-master$i -h vinay-hadoop-master$i --network-alias=vinay-hadoop-master$i hadoop-centos-secure)
    containerIds[$i]=${container_id:0:12};
    echo "vinay-hadoop-master$i" >> hosts
done

for i in $(seq $((N-2)));
do
    j=$(expr $i + 2)
    port_addition=$(expr $j \* 10000)
    dn_http_port=$(expr $port_addition + 9864)
    dn_https_port=$(expr $port_addition + 9865)
    container_id=$(docker run -p $dn_http_port:9864 -p $dn_https_port:9865 -d --net hadoopsecure.com --name vinay-hadoop-slave$i -h vinay-hadoop-slave$i --network-alias=vinay-hadoop-slave$i hadoop-centos-secure)
    containerIds[j]=${container_id:0:12};
    echo "vinay-hadoop-slave$i" >> hosts
done

# Copy the workers file to the master container
docker cp scripts ${containerIds[1]}:/root/scripts
docker cp scripts ${containerIds[2]}:/root/scripts
docker cp scripts ${containerIds[3]}:/root/scripts

docker cp hosts ${containerIds[1]}:/root/scripts
docker cp hosts ${containerIds[2]}:/root/scripts
docker cp hosts ${containerIds[3]}:/root/scripts
docker cp hosts ${containerIds[1]}:$HADOOP_HOME/etc/hadoop/workers
docker cp hosts ${containerIds[1]}:$HADOOP_HOME/etc/hadoop/slaves
docker cp hosts ${containerIds[2]}:$HADOOP_HOME/etc/hadoop/workers
docker cp hosts ${containerIds[2]}:$HADOOP_HOME/etc/hadoop/slaves

##Install kerberos
##It creates all principals and distribute to all nodes
docker exec -it ${containerIds[1]} /bin/bash /root/scripts/kerberos-config.sh installAllClients ${containerIds[1]}
docker exec -it ${containerIds[1]} /bin/bash /root/scripts/kerberos-config.sh installServer ${containerIds[1]}

#Setup ssl in all nodes
for host in ${containerIds[*]}; do
    docker exec -it $host /bin/rm -rf /root/scripts/ssl
    docker cp scripts/ssl $host:/root/scripts
    docker exec -it $host /bin/bash /root/scripts/install.sh setup-ssl
done

#
###Start the zookeeper
docker exec -it ${containerIds[1]} /bin/su -c '/bin/bash $ZK_HOME/bin/zkServer.sh start' zk
sleep 3
###Format ZKFC
docker exec -it ${containerIds[1]} /bin/su -c '/bin/bash $HADOOP_HOME/bin/hdfs zkfc -formatZK && rm -f /tmp/hadoop-hdfs-zkfc.pid' hdfs
###Start journal nodes
docker exec -it ${containerIds[1]} "${HADOOP_HOME}/bin/hdfs" \
    --workers \
    --hostnames "vinay-hadoop-master1 vinay-hadoop-master2 vinay-hadoop-slave1" \
    --daemon start \
    journalnode
sleep 3
##
###Format the Active namenode and start it
docker exec -it ${containerIds[1]} /bin/su -c '/bin/bash ${HADOOP_HOME}/bin/hdfs \
    namenode -format -force && rm -f /tmp/hadoop-hdfs-namenode.pid' hdfs
 
docker exec -it ${containerIds[1]} /bin/su -c '${HADOOP_HOME}/bin/hdfs \
    --daemon start namenode \
    && sleep 3 \
    && tail /var/log/hadoop/hdfs/hadoop-hdfs-namenode-$HOSTNAME.log' hdfs

docker exec -it ${containerIds[1]} /bin/su -c '${HADOOP_HOME}/bin/hdfs \
    --daemon start zkfc \
    && sleep 3 \
    && tail /var/log/hadoop/hdfs/hadoop-hdfs-zkfc-$HOSTNAME.log' hdfs

###Bootstrap the standby namenode and start it
docker exec -it ${containerIds[2]} /bin/su -c '${HADOOP_HOME}/bin/hdfs \
    namenode -bootstrapStandby \
    && rm -f /tmp/hadoop-hdfs-namenode.pid' hdfs

docker exec -it ${containerIds[2]} /bin/su -c '${HADOOP_HOME}/bin/hdfs \
    --daemon start namenode \
    && sleep 3 \
    && tail /var/log/hadoop/hdfs/hadoop-hdfs-namenode-$HOSTNAME.log' hdfs

docker exec -it ${containerIds[2]} /bin/su -c '${HADOOP_HOME}/bin/hdfs \
    --daemon start zkfc \
    && sleep 3 \
    && tail /var/log/hadoop/hdfs/hadoop-hdfs-zkfc-$HOSTNAME.log' hdfs

docker exec -it ${containerIds[1]} /bin/su -c 'kinit -kt $HOME/hdfs.$HOSTNAME.keytab \
    hdfs/$HOSTNAME' hdfs

docker exec -it ${containerIds[1]} /bin/cp /root/scripts/install.sh /home/hdfs/install.sh
docker exec -it ${containerIds[1]} /bin/chown hdfs:hadoop /home/hdfs/install.sh
docker exec -it ${containerIds[1]} /bin/chmod +x /home/hdfs/install.sh

docker exec -it ${containerIds[1]} /bin/su -c '/bin/bash /home/hdfs/install.sh init-hdfs-dirs' hdfs

## Start remaining hdfs and yarn services
docker exec -it ${containerIds[1]} $HADOOP_HOME/sbin/start-dfs.sh

docker exec -it ${containerIds[1]} $HADOOP_HOME/sbin/start-yarn.sh
#
## Connect to the master node
docker exec -it ${containerIds[1]} /bin/bash
