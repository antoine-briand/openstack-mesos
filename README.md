# Openstack-mesos
This is for automatically deploying Mesos and Marathon on Openstack platform with Terraform.
# How to start
1. Generates SSH Keys

  ```ssh-keygen -t rsa -f /Users/Clare/.ssh -C "mesos"```
2. Terraform

  Before you build you Mesos cluster, you should change something via your environment, like `public key`, `auth_url`, `image name` and so on, you refer to the following to do it.
  ```
  variable public_key { default = "~/.ssh/mesos.pub" }
variable auth_url { default = "your openstack auth_url" }
variable image_name { default = "CentOS7.2" }
variable flavor_name { default = "ocp.medium" }
variable ssh_private_key { default = "~/.ssh/mesos" }
variable ssh_user { default = "centos" }
variable master_count { default = "3" }
variable slave_count { default = "3" }
variable host_domain  { default = "novalocal" }


module "keypair" {
  source = "./mesos/keypair"
  public_key = "${var.public_key}"
  keypair_name = "mesos"
}

module "mesos" {
  source  = "./mesos/instances"
  auth_url = "${ var.auth_url }"
  tenant_id = "d3b2d330416643d3a7514941cb3a056a"
  tenant_name = "Mantl"
  flavor_name = "${ var.flavor_name }"
  network_id = "47ea2580-d843-4fe8-a61d-2c0e59bca4f2"
  image_name = "${ var.image_name }"
  keypair_name = "${ module.keypair.keypair_name }"
  ssh_private_key = "${ var.ssh_private_key }"
  security_groups = ""
  ssh_user = "${ var.ssh_user}"
  datacenter = "hf1"
  cluster = "mesos"
  master_count  = "${ var.master_count }"
  slave_count = "${ var.slave_count }"
  mesos_version  = "0.27.0"
  marathon_version = "0.15.2"
  host_domain = "${var.host_domain}"
}
  ```
3. Get Openstack RC File
  
  This can be done by logining your Openstack dashborad.
4. Start to build your Mesos cluster

  * Getting Configuration
    
    ```
    # terraform get
    Get: file:///Users/Clare/devops/terraform/openstack-mesos/mesos/keypair
    Get: file:///Users/Clare/devops/terraform/openstack-mesos/mesos/instances
    ```
  * Executing Plan
  ```
  # terrafrom plan
  ```
  * Applying Plan
  ```
  # terraform apply
  ```
  If all are right, your cluster can be built successfully. 

*Note: Please install Terraform in your enviroment, more please refer to [Terrafrom ](https://www.terraform.io)*.
