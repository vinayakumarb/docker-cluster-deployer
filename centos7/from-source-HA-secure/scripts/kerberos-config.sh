#!/bin/env bash
SCRIPT_NAME=$(basename $BASH_SOURCE)
DIR=$(dirname $BASH_SOURCE);
DIR=$(cd $DIR && pwd);

REALM="HADOOP.COM"
KDC_CONF_DIRECTORY=/var/kerberos/krb5kdc
myhostname=$(hostname)

COMMAND=$1;
KDC_SERVER=$2;
USER=$3;
shift 2
HOSTNAME=`hostname`
#
#Install the client configurations
#
function installClientConf() {
cat >/etc/krb5.conf <<EOF
[logging]
    default = FILE:/var/log/krb5libs.log
    kdc = FILE:/var/log/krb5kdc.log
    admin_server = FILE:/var/log/kadmind.log

[libdefaults]
    default_realm = ${REALM}
    dns_lookup_realm = false
    dns_lookup_kdc = false
    ticket_lifetime = 24h
    renew_lifetime = 7d
    forwardable = true

[realms]
    ${REALM} = {
        kdc = ${KDC_SERVER}
        admin_server = ${KDC_SERVER}
    }

[domain_realm]
    .hadoopsecure.com = ${REALM}
    ${HOSTNAME} = ${REALM}
EOF

  #Create /etc/hosts mapping of all machines
  # Check the /etc/hosts mapping
  hostname=$(hostname)
  sed "/$hostname/d" /etc/hosts > /etc/hosts.updated
  cat /etc/hosts.updated > /etc/hosts
  for host in $(cat $DIR/hosts); do
    ip=$(getent hosts $host | grep -v "::"| awk '{ print $1 }')
    if [[ -z "$ip" ]] && [[ "$host" == "$hostname" ]];then
      ip=$(ifconfig eth0|grep inet|awk '{print $2}')
    fi
    if [ -z "$ip" ]; then
      echo "$host is not resolvable to ip" >&2
      exit 1;
    fi
    echo "$ip    $host" >> /etc/hosts.updated
  done
  cat /etc/hosts.updated > /etc/hosts

}

#
# Check whether the hosts file exist
#
function checkHosts(){
  if ! [ -f $DIR/hosts ]; then
    echo "hosts file does not exist in $DIR" >&2;
    exit 1;
  fi
}

#
# Install the client configurations in all hosts
#
function installAllClients(){
  for host in $(cat $DIR/hosts); do
    ssh $host /bin/bash $DIR/$SCRIPT_NAME installClientConf $KDC_SERVER
  done
}

#
# Create the kerberos accounts for the specified host
#
function createPrincipals(){
  #FQDN for the principal
  host=$1;
  principal_host=$host

  echo "Creating HTTP accounts. Principal: HTTP. Password: hadoop"
  kadmin.local -q "addprinc -pw hadoop HTTP/$principal_host"
  kadmin.local -q "addprinc -pw hadoop host/$principal_host"

  echo "Creating HDFS accounts. Principal: nn,dn,jn. Password: hadoop"
  kadmin.local -q "addprinc -pw hadoop nn/$principal_host"
  kadmin.local -q "addprinc -pw hadoop dn/$principal_host"
  kadmin.local -q "addprinc -pw hadoop jn/$principal_host"
  kadmin.local -q "addprinc -pw hadoop hdfs/$principal_host"

  echo "Creating YARN accounts. Principal: yarn. Password: hadoop"
  kadmin.local -q "addprinc -pw hadoop rm/$principal_host"
  kadmin.local -q "addprinc -pw hadoop nm/$principal_host"
  kadmin.local -q "addprinc -pw hadoop yarn/$principal_host"

  echo "Creating MAPRED accounts. Principal: mapred. Password: hadoop"
  kadmin.local -q "addprinc -pw hadoop jhs/$principal_host"
  kadmin.local -q "addprinc -pw hadoop mapred/$principal_host"

  echo "Creating keytab for nn: nn.$host.keytab"
  kadmin.local -q "ktadd -norandkey -k $DIR/nn.$host.keytab host/$principal_host nn/$principal_host"
  echo "Creating keytab for dn: dn.$host.keytab"
  kadmin.local -q "ktadd -norandkey -k $DIR/dn.$host.keytab host/$principal_host dn/$principal_host"
  echo "Creating keytab for jn: jn.$host.keytab"
  kadmin.local -q "ktadd -norandkey -k $DIR/jn.$host.keytab host/$principal_host jn/$principal_host"
  echo "Creating keytab for nn: http.$host.keytab"
  kadmin.local -q "ktadd -norandkey -k $DIR/HTTP.$host.keytab HTTP/$principal_host"
  echo "Creating keytab for rm: rm.$host.keytab"
  kadmin.local -q "ktadd -norandkey -k $DIR/rm.$host.keytab host/$principal_host rm/$principal_host"
  echo "Creating keytab for nm: nm.$host.keytab"
  kadmin.local -q "ktadd -norandkey -k $DIR/nm.$host.keytab host/$principal_host nm/$principal_host"
  echo "Creating keytab for jhs: jhs.$host.keytab"
  kadmin.local -q "ktadd -norandkey -k $DIR/jhs.$host.keytab host/$principal_host jhs/$principal_host"

  echo "Creating keytab for jhs: client.$host.keytab"
  kadmin.local -q "ktadd -norandkey -k $DIR/hdfs.$host.keytab hdfs/$principal_host"
  kadmin.local -q "ktadd -norandkey -k $DIR/mapred.$host.keytab mapred/$principal_host"
  kadmin.local -q "ktadd -norandkey -k $DIR/yarn.$host.keytab yarn/$principal_host"

  #Distribute the keytabs to corresponding user
  cp $DIR/nn.$host.keytab /home/hdfs
  cp $DIR/dn.$host.keytab /home/hdfs
  cp $DIR/jn.$host.keytab /home/hdfs
  cp $DIR/hdfs.$host.keytab /home/hdfs
  cp $DIR/HTTP.$host.keytab /home/hdfs
  chown hdfs:hadoop /home/hdfs/*$host.keytab
  chmod 400 /home/hdfs/*$host.keytab

  cp $DIR/rm.$host.keytab /home/yarn
  cp $DIR/nm.$host.keytab /home/yarn
  cp $DIR/yarn.$host.keytab /home/yarn
  cp $DIR/HTTP.$host.keytab /home/yarn
  chown yarn:hadoop /home/yarn/*$host.keytab
  chmod 400 /home/yarn/*$host.keytab

  cp $DIR/jhs.$host.keytab /home/mapred
  cp $DIR/mapred.$host.keytab /home/mapred
  cp $DIR/HTTP.$host.keytab /home/mapred
  chown mapred:hadoop /home/mapred/*$host.keytab
  chmod 400 /home/mapred/*$host.keytab

  if [ "$host" == "$myhostname" ];then
    #Skip copying to same machine
    return;
  fi
  su -c "scp /home/hdfs/*$host.keytab hdfs@$host:/home/hdfs/" hdfs
  su -c "ssh hdfs@$host chmod 400 /home/hdfs/\*$host.keytab" hdfs
  su -c "scp /home/yarn/*$host.keytab yarn@$host:/home/yarn/" yarn
  su -c "ssh yarn@$host chmod 400 /home/yarn/\*$host.keytab" yarn
  su -c "scp /home/mapred/*$host.keytab mapred@$host:/home/mapred/" mapred
  su -c "ssh mapred@$host chmod 400 /home/mapred/\*$host.keytab" mapred
}

#
# Install the server configurations
#
function installServer(){
  checkHosts

  echo "Creating kadm5.acl file"
  cat >${KDC_CONF_DIRECTORY}/kadm5.acl <<EOF
*/admin@${REALM}    *
EOF

  echo "Creating KDC database"
  kdb5_util create -s -P hadoop

  echo "Creating administriative account. Principal: admin/admin. Password: hadoop"
  kadmin.local -q "addprinc -pw hadoop admin/admin"

  echo "Starting services"
  chkconfig krb5kdc on
  chkconfig kadmin on

  systemctl start krb5kdc
  systemctl start kadmin

  for host in $(cat $DIR/hosts); do
    createPrincipals $host
  done
}

$COMMAND $@
