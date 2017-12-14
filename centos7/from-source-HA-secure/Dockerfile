# Dockerfile for installing the necessary dependencies for running Hadoop and Spark
FROM centos:7

MAINTAINER Vinayakumar B vinayakumarb@apache.org

RUN yum install -y epel-release
RUN yum -y update
RUN yum install -y wget ntp sudo 

# configure ssh free key access
RUN yum install -y which openssh-clients openssh-server
RUN echo 'root:hortonworks' | chpasswd
RUN ssh-keygen -t rsa -f ~/.ssh/id_rsa -P '' && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
RUN sed -i '/pam_loginuid.so/c session    optional     pam_loginuid.so'  /etc/pam.d/sshd
RUN echo -e "Host *\n StrictHostKeyChecking no" >> /etc/ssh/ssh_config

#Install JDK
RUN yum install -y java-1.8.0-openjdk
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV PATH $PATH:$JAVA_HOME/bin

# install general tools
RUN yum install -y iproute2 vim inetutils-ping dnsutils lsof 

#Installing kerberos server 
RUN yum install -y krb5-server krb5-libs krb5-workstation

#Installing curl
RUN yum install -y curl net-tools 

RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;
VOLUME [ "/sys/fs/cgroup" ]

RUN yum clean all && systemctl enable sshd.service

EXPOSE 22

CMD ["/usr/sbin/init"]
