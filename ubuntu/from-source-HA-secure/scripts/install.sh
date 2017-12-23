#!/bin/env bash
SCRIPT_NAME=$(basename $BASH_SOURCE)
DIR=$(dirname $BASH_SOURCE);
DIR=$(cd $DIR && pwd);

function usage() {
    echo "Usage: ./install.sh <COMMAND> [options]"
    echo
    echo "setupusers --users <USERS>:<GROUP>"
    echo      "create users and map to specified group"
}

function createUser(){
    username=$1;
    groupname=$2;
    useradd -d /home/$username -m -g $groupname $username

    su -c 'ssh-keygen -t rsa -f ~/.ssh/id_rsa -N "" \
    && cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys \
    && echo "HashKnownHosts no" >> ~/.ssh/config \
    && echo "StrictHostKeyChecking no" >> ~/.ssh/config' $username
}

function createGroup(){
    groupname=$1;
    groupadd $groupname || true
}

function setupUsers(){
    local USERS;
    local GROUP;
    while [ "$1" != "" ]; do
        PARAM=`echo $1 | awk -F= '{print $1}'`
        VALUE=`echo $1 | awk -F= '{print $2}'`
        case $PARAM in
            -h | --help)
                usage
                exit
                ;;
            --users)
                USERS=$(echo $VALUE|awk -F: '{print $1}')
                GROUP=$(echo $VALUE|awk -F: '{print $2}')
                ;;
            *)
                echo "ERROR: unknown parameter \"$PARAM\""
                usage
                exit 1
                ;;
        esac
        shift
    done

    createGroup $GROUP
    for user in $(echo $USERS|tr ',' '\n'); do
       createUser $user $GROUP
    done
}

function initHdfsDirs(){
    $HADOOP_HOME/bin/hdfs dfs -chmod 755 /
    $HADOOP_HOME/bin/hdfs dfs -mkdir -p /tmp/hadoop-yarn/staging/hdfs /tmp/hadoop-yarn/staging/yarn /tmp/hadoop-yarn/staging/client /user/yarn /user/hdfs /user/client /user/mapred /yarn/app-logs /mapred/jobhistory/intermediate-done /mapred/jobhistory/done
    $HADOOP_HOME/bin/hdfs dfs -chmod +rwxt /tmp /yarn/app-logs /mapred/jobhistory/intermediate-done
    $HADOOP_HOME/bin/hdfs dfs -chown hdfs:hadoop /tmp /user
    $HADOOP_HOME/bin/hdfs dfs -chmod 755 /user
    $HADOOP_HOME/bin/hdfs dfs -chmod 700 "/user/*"
    $HADOOP_HOME/bin/hdfs dfs -chown -R yarn:hadoop /yarn /tmp/hadoop-yarn /user/yarn
    $HADOOP_HOME/bin/hdfs dfs -chown -R hdfs:hadoop /yarn /tmp/hadoop-yarn/staging/hdfs
    $HADOOP_HOME/bin/hdfs dfs -chown -R mapred:hadoop /mapred /user/mapred
    $HADOOP_HOME/bin/hdfs dfs -chown -R client:users /yarn /tmp/hadoop-yarn/staging/client /user/client
    $HADOOP_HOME/bin/hdfs dfs -ls -R /
}

#Setup the SSL prerequirements
# CA is created outside and kept static, it will be available in /root/scripts directory for signing certificate
#1. Create the certificate for each node
#2. Sign the certificate with the CA
#3. Add the Signed certificate and CA certificate to keystore of each node
function setupSsl(){
    password=${1:-hadoopkeystorepass}
    ssldir=$HOME/scripts/ssl
    mkdir -p $ssldir
    #1 Generate the key
    keytool -keystore $ssldir/keystore -alias $(hostname) -keyalg RSA -keysize 2048 -validity 7 -genkey -storepass $password -keypass $password -storetype pkcs12 -dname "CN=$(hostname), OU=ASF, O=ASF, L=BGLR, S=KAR, C=IN"
    #2 Export the key as certificate
    keytool -keystore $ssldir/keystore -alias $(hostname) -certreq -storepass $password -keypass $password -file $ssldir/$(hostname).cert
    #3 Add CA certificate to truststore
    keytool -keystore $ssldir/truststore -alias CARoot -import -file $ssldir/ca.cert -noprompt -storepass $password -keypass $password -storetype pkcs12
    #4 Sign the certificate with CA certificate
    openssl x509 -req -CA $ssldir/ca.cert -CAkey $ssldir/ca.key -in $ssldir/$(hostname).cert -out $ssldir/$(hostname).cert.signed -days 7 -CAcreateserial
    #5 Import CA certicate and signed certificate to keystore
    keytool -keystore $ssldir/keystore -alias CARoot -import -file $ssldir/ca.cert -noprompt -storepass $password -keypass $password -storetype pkcs12
    keytool -keystore $ssldir/keystore -alias $(hostname) -import -file $ssldir/$(hostname).cert.signed -noprompt -storepass $password -keypass $password -storetype pkcs12
    #6 copy the keystore and truststore to hadoop conf directory and limit the permissions to only owner and hadoop special group
    cp $ssldir/keystore $ssldir/truststore $HADOOP_HOME/etc/hadoop
    chown hdfs:hadoop $HADOOP_HOME/etc/hadoop/keystore $HADOOP_HOME/etc/hadoop/truststore
    chmod 660 $HADOOP_HOME/etc/hadoop/keystore $HADOOP_HOME/etc/hadoop/truststore
}

function main(){
    COMMAND=$1;
    shift
    case $COMMAND in
        "setupusers")
            setupUsers $@
            ;;
        "init-hdfs-dirs")
            initHdfsDirs $@
            ;;
        "setup-ssl")
            setupSsl $@
            ;;
        *)
            echo "ERROR: Unknown command \"$COMMAND\""
            usage
            exit 1
    esac
}

main $@