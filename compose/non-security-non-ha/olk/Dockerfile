ARG IMAGE_VERSION=latest
ARG USER_NAME=hadoop;
ARG BASE_IMAGE=hadoop;
FROM ${BASE_IMAGE}-${USER_NAME}:${IMAGE_VERSION}

ADD olk /olk
ENV OLK_HOME=/olk
ENV PATH=$PATH:$OLK_HOME/bin
RUN chown ${USER_NAME}:users -R /olk

EXPOSE 9080