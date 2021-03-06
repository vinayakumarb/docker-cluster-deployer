# Dockerfile for installing the necessary dependencies for running Hadoop and Spark
FROM centos:6

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

RUN yum -y install supervisor
RUN mkdir /etc/supervisor.d/
RUN echo -e "[program:sshd]\ncommand=/sbin/service sshd start" >> /etc/supervisord.conf
RUN echo -e "[program:ntpd]\ncommand=/sbin/service ntpd start" >> /etc/supervisord.conf

#Install JDK
RUN yum install -y java-1.8.0-openjdk
ENV JAVA_HOME /usr/lib/jvm/jre-1.8.0-openjdk.x86_64
ENV PATH $PATH:$JAVA_HOME/bin

# install general tools
RUN yum install -y iproute2 vim inetutils-ping dnsutils lsof 

#Installing kerberos server 
RUN yum install -y krb5-server krb5-libs krb5-workstation

#Installing curl
RUN yum install -y curl net-tools 

RUN yum clean all

EXPOSE 22

CMD /usr/bin/supervisord -n

