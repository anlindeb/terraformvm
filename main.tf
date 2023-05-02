# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "vsphere" {
  vsphere_server = var.vsphere_server
  user           = var.vsphere_user
  password       = var.vsphere_password

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = var.datacenter
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore" {
  name          = var.datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.network_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = "/${var.datacenter}/vm/${var.template_name}"
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "vmname" {
  name             = "vmname"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus = 2
  memory   = 1024

  network_interface {
    network_id = data.vsphere_network.network.id
  }

  wait_for_guest_net_timeout = -1
  wait_for_guest_ip_timeout  = -1

  disk {
    label            = "disk0"
    thin_provisioned = true
    size             = 32
  }

  guest_id = "ubuntu64Guest"

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    customize {
      linux_options {
        host_name = "hello-world"
        domain    = "example.com"
      }
      network_interface {
        ipv4_address = "172.16.11.10"
        ipv4_netmask = 24
      }
      ipv4_gateway = "172.16.11.1"
    }
  }
}

output "vm_ip" {
  value = vsphere_virtual_machine.vmname.guest_ip_addresses
}