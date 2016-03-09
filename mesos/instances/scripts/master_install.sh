#!/bin/bash

source /tmp/mesos_metadata.sh

if [ -z "$MARATHON_VERSION" ]
then
    echo "Mesos version: $MARATHON_VERSION is not set"
    exit 1
fi

sudo yum install -y marathon-$MARATHON_VERSION mesosphere-zookeeper
if [ $? -eq 0 ]
then
    echo "Successfully installed Marathon $MARATHON_VERSION and Zookeeper"
    exit 0
else
	echo "Faild to install Marathon $MARATHON_VERSION and Zookeeper"
	exit 1
fi
