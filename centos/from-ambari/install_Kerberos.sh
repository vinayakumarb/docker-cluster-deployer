
#!/bin/sh

echo "Installing Kerberos"
yum install -y krb5-server krb5-libs krb5-workstation

echo "Using default configuration"
REALM="EXAMPLE.COM"

HOSTNAME=`hostname`
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
        kdc = ${HOSTNAME}
        admin_server = ${HOSTNAME}
    }

[domain_realm]
    .${HOSTNAME} = ${REALM}
    ${HOSTNAME} = ${REALM}
EOF

echo "Creating kadm5.acl file"
cat >/var/kerberos/krb5kdc/kadm5.acl <<EOF
*/admin@${REALM}    *
EOF

echo "Creating KDC database"
kdb5_util create -s -P hadoop

echo "Creating administriative account. Principal: admin/admin. Password: ambari"
kadmin.local -q "addprinc -pw ambari admin/admin"

echo "Starting services"
service krb5kdc start
service kadmin start

chkconfig krb5kdc on
chkconfig kadmin on

#!/bin/sh

echo "Installing Kerberos"
yum install -y krb5-server krb5-libs krb5-workstation

echo "Using default configuration"
REALM="EXAMPLE.COM"

HOSTNAME=`hostname`
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
        kdc = ${HOSTNAME}
        admin_server = ${HOSTNAME}
    }

[domain_realm]
    .${HOSTNAME} = ${REALM}
    ${HOSTNAME} = ${REALM}
EOF

echo "Creating kadm5.acl file"
cat >/var/kerberos/krb5kdc/kadm5.acl <<EOF
*/admin@${REALM}    *
EOF

echo "Creating KDC database"
kdb5_util create -s -P hadoop

echo "Creating administriative account. Principal: admin/admin. Password: ambari"
kadmin.local -q "addprinc -pw ambari admin/admin"

echo "Starting services"
service krb5kdc start
service kadmin start

chkconfig krb5kdc on
chkconfig kadmin on

#!/bin/sh

echo "Installing Kerberos"
yum install -y krb5-server krb5-libs krb5-workstation

echo "Using default configuration"
REALM="EXAMPLE.COM"

HOSTNAME=`hostname`
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
        kdc = ${HOSTNAME}
        admin_server = ${HOSTNAME}
    }

[domain_realm]
    .${HOSTNAME} = ${REALM}
    ${HOSTNAME} = ${REALM}
EOF

echo "Creating kadm5.acl file"
cat >/var/kerberos/krb5kdc/kadm5.acl <<EOF
*/admin@${REALM}    *
EOF

echo "Creating KDC database"
kdb5_util create -s -P hadoop

echo "Creating administriative account. Principal: admin/admin. Password: ambari"
kadmin.local -q "addprinc -pw ambari admin/admin"

echo "Starting services"
service krb5kdc start
service kadmin start

chkconfig krb5kdc on
chkconfig kadmin on

#!/bin/sh

echo "Installing Kerberos"
yum install -y krb5-server krb5-libs krb5-workstation

echo "Using default configuration"
REALM="EXAMPLE.COM"

HOSTNAME=`hostname`
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
        kdc = ${HOSTNAME}
        admin_server = ${HOSTNAME}
    }

[domain_realm]
    .${HOSTNAME} = ${REALM}
    ${HOSTNAME} = ${REALM}
EOF

echo "Creating kadm5.acl file"
cat >/var/kerberos/krb5kdc/kadm5.acl <<EOF
*/admin@${REALM}    *
EOF

echo "Creating KDC database"
kdb5_util create -s -P hadoop

echo "Creating administriative account. Principal: admin/admin. Password: ambari"
kadmin.local -q "addprinc -pw ambari admin/admin"

echo "Starting services"
service krb5kdc start
service kadmin start

chkconfig krb5kdc on
chkconfig kadmin on
