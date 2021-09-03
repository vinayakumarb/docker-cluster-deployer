ARG IMAGE_VERSION=latest
ARG USER_NAME=hadoop;
ARG BASE_IMAGE=hadoop;
FROM ${BASE_IMAGE}-${USER_NAME}:${IMAGE_VERSION}

RUN apt-get clean

ADD derby /derby
RUN mkdir -p /derby/data

ENV DERBY_HOME=/derby
ENV PATH=$PATH:$DERBY_HOME/bin

RUN chown ${USER_NAME}:users -R /derby

EXPOSE 1527