variable public_key { default = "~/.ssh/mesos.pub" }
variable auth_url { default = "https://hf1-keystone-srv.qa.webex.com:443/v2.0" }
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
