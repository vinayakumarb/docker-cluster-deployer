FROM ubuntu:latest

ARG USER_NAME=hadoop;
ARG USER_ID=1001;
ARG GROUP_ID=1001;

MAINTAINER Vinayakumar B <vinayakumarb@apache.org>

RUN apt-get update -y
RUN apt-get upgrade -y

# install openjdk
RUN apt-get install -y openjdk-8-jdk
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

# install and configure ssh service
RUN apt-get install -y openssh-server \
    && mkdir -p /var/run/sshd
# configure ssh free key access
RUN echo 'root:hadoop123' | chpasswd
RUN ssh-keygen -t rsa -f ~/.ssh/id_rsa -N "" \
    && cat /root/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys \
    && echo "HashKnownHosts no" >> ~/.ssh/config \
    && echo "StrictHostKeyChecking no" >> ~/.ssh/config

# set supervisor
RUN apt-get install -y supervisor
RUN echo "[program:sshd]" >> /etc/supervisor/supervisord.conf \
    && echo "command=/usr/sbin/sshd -D" >> /etc/supervisor/supervisord.conf

# install general tools
RUN apt-get install -y iproute2 vim inetutils-ping
RUN apt-get clean

RUN rm -f /var/log/faillog /var/log/lastlog
RUN groupadd --non-unique -g ${GROUP_ID} ${USER_NAME}
RUN useradd -g ${GROUP_ID} -u ${USER_ID} -k /root -m -s /bin/bash ${USER_NAME}
RUN mkdir -p /etc/sudoers.d/
RUN echo "${USER_NAME} ALL=NOPASSWD: ALL" > "/etc/sudoers.d/hadoop-${USER_ID}"
ENV HOME /home/${USER_NAME}

ENV USER_NAME=${USER_NAME}
ENV USER_ID=${USER_ID}
ENV GROUP_ID=${GROUP_ID}

EXPOSE 22

CMD /usr/bin/supervisord -n