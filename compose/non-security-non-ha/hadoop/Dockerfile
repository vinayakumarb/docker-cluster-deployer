ARG USER_NAME=hadoop;
FROM hadoop-runner-${USER_NAME}:base
#Configure hadoop related items
ENV HADOOP_HOME /hadoop
ENV HDFS_NAMENODE_USER ${USER_NAME}
ENV HDFS_DATANODE_USER ${USER_NAME}
ENV HDFS_SECONDARYNAMENODE_USER ${USER_NAME}
ENV YARN_RESOURCEMANAGER_USER ${USER_NAME}
ENV YARN_NODEMANAGER_USER ${USER_NAME}
ENV HADOOP_IDENT_STRING ${USER_NAME}
ADD hadoop /hadoop
ENV PATH $PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
RUN chown ${USER_NAME}:users -R /hadoop

RUN hdfs namenode -format

EXPOSE 9820 9870 9864 9866 9867
