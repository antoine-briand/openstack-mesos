#!/bin/bash

# set hostname
IP=`hostname -i`
sudo sh -c "echo ${IP} > /etc/mesos-slave/hostname"

# set containerizers
sudo sh -c "echo 'docker,mesos' > /etc/mesos-slave/containerizers"

# logging level
sudo sh -c "echo 'WARNING' > /etc/mesos-slave/logging_level"

echo "Stop Mesos Master service if started ... ... " #>>/tmp/install_log
sudo systemctl disable mesos-master
sudo systemctl stop mesos-master
sleep 10
sudo su -c "ps -ef | grep mesos-master | grep -v grep >>/dev/nul" 
if [ $? -eq 1 ]
then
    echo "Successfully stop Mesos Master Service" 
else
    echo "Faild to stop Mesos Master Service" 
fi

# start the slave process
echo "Start Mesos Slave service ... ..." 
sudo systemctl enable mesos-slave
sudo systemctl start mesos-slave
sleep 10
sudo su -c "ps -ef | grep mesos-slave | grep -v grep >>/dev/nul" 
if [ $? -eq 0 ]
then
    echo "Successfully start Mesos slave Service" 
else
    echo "Faild to start Mesos slave Service" 
fi

echo "Start Docker service ... ... " 
sudo systemctl enable docker
sudo systemctl start docker
sleep 10
sudo su -c "ps -ef | grep docker | grep -v grep >>/dev/nul" 
if [ $? -eq 0 ]
then
    echo "Successfully start Docker Service" 
else
    echo "Faild to start Docker Service" 
fi
