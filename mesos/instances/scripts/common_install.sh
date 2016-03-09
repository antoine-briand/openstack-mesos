#!/bin/bash

# increase timeouts in YUM
sudo yum-config-manager --save --setopt timeout=300
sudo yum-config-manager --save --setopt minrate=1
sudo yum-config-manager --save --setopt retries=30

sudo yum -y update
sudo yum install -y docker
