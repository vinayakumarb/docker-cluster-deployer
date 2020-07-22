ARG USER_NAME=hadoop;
FROM hadoop-runner-${USER_NAME}:base
RUN apt-get clean

ADD derby /derby
RUN mkdir -p /derby/data

ENV DERBY_HOME=/derby
ENV PATH=$PATH:$DERBY_HOME/bin

EXPOSE 1527