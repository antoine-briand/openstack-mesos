variable master_count { default = "3" }
variable slave_count { default = "5" }
variable datacenter { default = "hf1" }
variable cluster { default = "mesos" }
variable count_format { default = "%02d" }
variable image_name { }
variable flavor_name { }
variable security_groups { }
variable network_id { }
variable ssh_user { }
variable ssh_private_key { }
variable marathon_version { }
variable mesos_version { }
variable auth_url { }
variable tenant_id { }
variable tenant_name { }
variable keypair_name {}
variable host_domain  { }

provider "openstack" {
  auth_url = "${ var.auth_url }"
  tenant_id     = "${ var.tenant_id }"
  tenant_name   = "${ var.tenant_name }"
}

resource "openstack_compute_instance_v2" "master" {
  name = "${ var.datacenter}-${var.cluster}-master-${format(var.count_format, count.index+1) }"
  image_name = "${var.image_name}"
  flavor_name = "${var.flavor_name}"
  key_pair = "${ var.keypair_name }"
  security_groups = [ "${var.security_groups}" ]
  network = {uuid = "${var.network_id}"}
  
  # declare metadata for configuration of the node
  metadata {
    master_count = "${var.master_count}"
    cluster_name = "${var.cluster}"
    myid = "${count.index + 1}"
    mesos_version = "${var.mesos_version}"
    marathon_version = "${var.marathon_version}"
  }
  
  # define default connection for remote provisioners
  connection {
    user = "${var.ssh_user}"
    private_key = "${file(var.ssh_private_key)}"
  }
  
  # write MYID,MASTER_COUNT,CLUSTER_NAME,MARATHON_VERSION,MESOS_VERSION to local file for using to install mesos
  provisioner "remote-exec" {
    inline = [
      "echo MYID=${self.metadata.myid} >/tmp/mesos_metadata.sh",
      "echo MASTER_COUNT=${self.metadata.master_count} >>/tmp/mesos_metadata.sh",
      "echo CLUSTER_NAME=${self.metadata.cluster_name} >>/tmp/mesos_metadata.sh",
      "echo MARATHON_VERSION=${self.metadata.marathon_version} >>/tmp/mesos_metadata.sh",
      "echo MESOS_VERSION=${self.metadata.mesos_version} >>/tmp/mesos_metadata.sh"
      ]
  }
  
  # for installing dedicated version Mesos slave
  provisioner "local-exec" {
    command = "echo MESOS_VERSION=${self.metadata.mesos_version} >${path.module}/scripts/output_mesos_metadata.sh"
  }
  
  # install mesos, docker
  provisioner "remote-exec" {
    scripts = [
      "${path.module}/scripts/common_install.sh",
      "${path.module}/scripts/mesos_install.sh",
      "${path.module}/scripts/master_install.sh"
    ]
  }
  
  count = "${var.master_count}"
}

resource "openstack_compute_instance_v2" "slave" {
  depends_on = ["openstack_compute_instance_v2.master"]
  
  count = "${var.slave_count}"
  name = "${ var.datacenter}-${var.cluster}-slave-${format(var.count_format,count.index + 1)}"
  image_name = "${var.image_name}"
  key_pair = "${ var.keypair_name }"
  flavor_name = "${var.flavor_name}"
  security_groups = [ "${var.security_groups}" ]
  network = {uuid = "${var.network_id}"}

  # define default connection for remote provisioners
  connection {
    user = "${var.ssh_user}"
    private_key = "${file(var.ssh_private_key)}"
  }
  
  provisioner "file" {
      source = "${path.module}/scripts/output_mesos_metadata.sh"
      destination = "/tmp/mesos_metadata.sh"
  }
 
  # install mesos, docker
  provisioner "remote-exec" {
    scripts = [
      "${path.module}/scripts/common_install.sh",
      "${path.module}/scripts/mesos_install.sh",
      "${path.module}/scripts/slave_install.sh"
    ]
  }
}

resource "null_resource" "master" {
   count = "${var.master_count}"

   depends_on = ["openstack_compute_instance_v2.master"]

   connection {
      user = "${var.ssh_user}"
      private_key = "${file(var.ssh_private_key)}"
      host = "${element(openstack_compute_instance_v2.master.*.access_ip_v4, count.index)}"
   }
 
   provisioner "local-exec" {
      command = "echo MASTER_IPS=${join(",", openstack_compute_instance_v2.master.*.access_ip_v4)} >${path.module}/scripts/output_master_ips.sh"
   }
   
   provisioner "remote-exec" {
      inline = [ "echo MASTER_IPS=${join(",", openstack_compute_instance_v2.master.*.access_ip_v4)} >/tmp/master_ips.sh" ]
   }
   
   provisioner "remote-exec" {
      inline = ["echo -e ${element(openstack_compute_instance_v2.master.*.access_ip_v4, count.index)}\t${element(openstack_compute_instance_v2.master.*.name, count.index)}.${var.host_domain}\t${element(openstack_compute_instance_v2.master.*.name, count.index)} >/tmp/hosts"]
   }
   
   provisioner "remote-exec"{
      scripts = [
        "${path.module}/scripts/set_hosts_file.sh",
        "${path.module}/scripts/common_config.sh",
        "${path.module}/scripts/master_config.sh" 
      ]
   }
}

resource "null_resource" "slave" {
   count = "${var.slave_count}"

   depends_on = ["openstack_compute_instance_v2.slave"]

   connection {
      user = "${var.ssh_user}"
      private_key = "${file(var.ssh_private_key)}"
      host = "${element(openstack_compute_instance_v2.slave.*.access_ip_v4, count.index)}"
   }
   
   provisioner "remote-exec" {
      inline = ["echo -e ${element(openstack_compute_instance_v2.slave.*.access_ip_v4, count.index)}\t${element(openstack_compute_instance_v2.slave.*.name, count.index)}.${var.host_domain}\t${element(openstack_compute_instance_v2.slave.*.name, count.index)} >/tmp/hosts"]
   }
   
   provisioner "file" {
     source = "${path.module}/scripts/output_master_ips.sh"
     destination = "/tmp/master_ips.sh"
   }
   
   provisioner "remote-exec" {
      scripts = [
        "${path.module}/scripts/set_hosts_file.sh",
        "${path.module}/scripts/common_config.sh",
        "${path.module}/scripts/slave_config.sh"
      ]
   }
}