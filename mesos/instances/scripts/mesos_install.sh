#!/bin/bash

source /tmp/mesos_metadata.sh

if [ -z "$MESOS_VERSION" ]
then
	echo "Mesos version: $MESOS_VERSION is not set"
	exit 1
fi

# Setup
sudo rpm -q mesos-${MESOS_VERSION}
if [ $? -eq 0 ]
then
	echo "Mesos ${MESOS_VERSION} is already installed"
	exit $?
fi

# Add the repository
sudo rpm -Uvh http://repos.mesosphere.io/el/7/noarch/RPMS/mesosphere-el-repo-7-1.noarch.rpm
sudo yum -y update

# Generate locale
sudo locale-gen en_US.UTF-8

# Try to install Mesos from a package
sudo yum install -y mesos-${MESOS_VERSION}

if [ $? -eq 0 ]
then
	echo "Successfully installed Mesos $MESOS_VERSION"
	exit 0
else
	echo "Faild to install Mesos $MESOS_VERSION"
	exit 1
fi
