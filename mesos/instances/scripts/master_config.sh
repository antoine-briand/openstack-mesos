#!/bin/bash 
echo "getting metadata......" 
source /tmp/master_ips.sh
source /tmp/mesos_metadata.sh 

MASTER_IPS=${MASTER_IPS}
MYID=${MYID}
CLUSTER_NAME=${CLUSTER_NAME}
MASTER_COUNT=${MASTER_COUNT}

#### ZOOKEEPER stuff

# populate zoo.cfg
echo "writing /etc/zookeeper/conf/zoo.cfg" 
IPS=$(echo $MASTER_IPS | tr "," "\n")

i=0
for IP in $IPS
do
    ((i++))
    echo "adding server ${i}"
    sudo sh -c "echo server.${i}=${IP}:2888:3888 >>/etc/zookeeper/conf/zoo.cfg"
done

# set myid
echo "setting myid" 
sudo sh -c "echo ${MYID} > /var/lib/zookeeper/myid"

### MESOS stuff

#quorum
# qourum is number of masters divided by 2, + 1)
QUORUM=$((${MASTER_COUNT}/2+1))
# write the quorum to the file
sudo sh -c "echo ${QUORUM} > /etc/mesos-master/quorum"

#set hostname
IP=`hostname -i`
sudo sh -c "echo ${IP} > /etc/mesos-master/hostname"

# cluster name
sudo sh -c "echo ${CLUSTER_NAME} > /etc/mesos-master/cluster"
# logging level
sudo sh -c "echo 'WARNING' > /etc/mesos-master/logging_level"


#### MARATHON stuff
# create the config dir
sudo mkdir -p /etc/marathon/conf
# copy the hostname file from mesos
sudo cp /etc/mesos-master/hostname /etc/marathon/conf
# copy zk file from mesos
sudo cp /etc/mesos/zk /etc/marathon/conf/master
# and again
sudo cp /etc/mesos/zk /etc/marathon/conf
# replace mesos with marathon
sudo sed -i -e 's|mesos$|marathon|' /etc/marathon/conf/zk
# enable the artifact store
sudo mkdir -p /etc/marathon/store
sudo sh -c "echo 'file:///etc/marathon/store' > /etc/marathon/conf/artifact_store"
sudo sh -c "echo 'warn' > /etc/marathon/conf/logging_level"

##### service stuff
# stop mesos slave process, if running
echo "Stop Mesos Slave service if started ... ... "
# disable automatic start of mesos slave
sudo systemctl disable mesos-slave
sudo systemctl stop mesos-slave
sleep 10
sudo sh -c "ps -ef | grep mesos-slave | grep -v grep >>/dev/nul" 
if [ $? -eq 1 ]
then
    echo "Successfully stop Mesos Slave Service" 
else
    echo "Faild to stop Mesos Slave Service" 
fi

# restart zookeeper
echo "Starting Zookeeper service ... ... " 
sudo systemctl enable zookeeper
sudo systemctl start zookeeper
sleep 10
sudo sh -c "ps -ef | grep zookeeper | grep -v grep >>/dev/nul" 
if [ $? -eq 0 ]
then
    echo "Successfully start Zookeeper Service" 
else
    echo "Faild to start Zookeeper Service" 
fi

# start mesos master
echo "Start Mesos Master service ... ..." 
sudo systemctl enable mesos-master
sudo systemctl start mesos-master
sleep 10
sudo sh -c "ps -ef | grep mesos-master | grep -v grep >>/dev/nul" 
if [ $? -eq 0 ]
then
    echo "Successfully start Mesos Master Service" 
else
    echo "Faild to start Mesos Master Service" 
fi

# start marathon
echo "Starting Marathon service ... ... " 
sudo systemctl enable marathon
sudo systemctl start marathon
sleep 10
sudo su -c "ps -ef | grep marathon | grep -v grep >>/dev/nul" 
if [ $? -eq 0 ]
then
    echo "Successfully start Marathon Service" 
else
    echo "Faild to start Marathon Service" 
fi
