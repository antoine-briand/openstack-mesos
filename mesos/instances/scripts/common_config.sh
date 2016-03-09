#!/bin/bash

source /tmp/master_ips.sh

MASTER_IPS=$MASTER_IPS 

### MESOS stuff
# set zk connection string
# initialize
ZK="zk://"
IPS=$(echo $MASTER_IPS | tr "," "\n")

for IP in $IPS
do
    ZK+="${IP}:2181,"
done

# strip trailing comma
ZK=${ZK::-1}
# add path
ZK+="/mesos"
#put it in the file
sudo sh -c "echo ${ZK} > /etc/mesos/zk"

sudo sh -c "grep ^SELINUX=enforcing$ /etc/selinux/config >>/dev/nul"
if [ $? -eq 0 ]
then
    sudo sh -c "sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/g' /etc/selinux/config"
fi