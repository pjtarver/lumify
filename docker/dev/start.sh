#!/bin/bash

function start_msg {
  echo -e "\n\e[32mStarting $1\n---------------------------------------------------------------\e[0m"
}

function start_sshd {
  service sshd start
}

function start_zookeeper {
  start_msg "ZooKeeper"
  /opt/zookeeper/bin/zkServer.sh start
}

function start_hadoop {
  start_msg "Hadoop"
  sed s/HOSTNAME/$HOSTNAME/ /opt/hadoop/etc/hadoop/core-site.xml.template > /opt/hadoop/etc/hadoop/core-site.xml
  mkdir -p /var/log/hadoop

  if [ ! -d "/tmp/hadoop-root" ]; then
    /opt/hadoop/bin/hdfs namenode -format
  fi
  /opt/hadoop/sbin/start-dfs.sh
  /opt/hadoop/sbin/start-yarn.sh
  /opt/hadoop/bin/hdfs dfsadmin -safemode wait
}

function start_accumulo {
  start_msg "Accumulo"
  echo $HOSTNAME > /opt/accumulo/conf/masters
  echo $HOSTNAME > /opt/accumulo/conf/slaves
  echo $HOSTNAME > /opt/accumulo/conf/tracers
  echo $HOSTNAME > /opt/accumulo/conf/gc
  echo $HOSTNAME > /opt/accumulo/conf/monitor
  mkdir -p /var/log/accumulo

  if [ $(/opt/hadoop/bin/hadoop fs -ls /user | grep accumulo | wc -l) == "0" ]; then
    echo "Creating accumulo user in hdfs"
    /opt/hadoop/bin/hadoop fs -mkdir -p /user/accumulo
    /opt/hadoop/bin/hadoop fs -chown accumulo /user/accumulo
  fi

  if /opt/accumulo/bin/accumulo info 2>&1 | grep --quiet "Accumulo not initialized"; then
    /opt/accumulo/bin/accumulo init --instance-name lumify --password secret --clear-instance-name
  fi
  /opt/accumulo/bin/start-all.sh
}

function start_elasticsearch {
  start_msg "Elasticsearch"
  mkdir -p /var/log/elasticsearch

  /opt/elasticsearch/bin/elasticsearch > /dev/null &
}

function start_rabbitmq {
  start_msg "RabbitMQ"
  /opt/rabbitmq/sbin/rabbitmq-server > /dev/null &
  /opt/rabbitmq/sbin/rabbitmq-plugins enable rabbitmq_management
}

start_sshd
start_zookeeper
start_hadoop
start_accumulo
start_elasticsearch
start_rabbitmq
/bin/bash