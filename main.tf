terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      version = "3.0.1-rc4"
    }
  }
}


provider "proxmox" {
  pm_api_url        = "https://192.168.24.10:8006/api2/json"
  pm_api_token_id   = "root@pam!test"
  pm_api_token_secret = "77f7ffc9-af38-4a95-9e97-66b9f23bf5f6"
  pm_tls_insecure   = true
}

resource "proxmox_vm_qemu" "k3s_control_plane" {
  count        = var.control_plane_count
  name         = "control-plane-${count.index + 1}" 
  target_node  = var.proxmox_host
  clone        = var.template_name
  agent        = 1
  os_type      = "126"
  cores        = 2
  sockets      = 2
  memory       = 16384
  bootdisk     = "scsi0"
  scsihw       = "virtio-scsi-pci"  

  disk {
    slot         = "scsi0"
    size         = "200G"
    type         = "disk"
    storage      = "data"
    backup       = true
    iothread     = true
  }

## disk {
##    slot    = "ide1"
##    type    = "cdrom"
##    storage = "local"
##    size    = "4G"
##    iso  = "local:iso/ubuntu-24.04.1-live-server-amd64.iso"
##  }

  disk {
    slot    = "ide2"
    type    = "cloudinit"
    storage = "data"
  }

  ciuser      = "systemadmin"
  cipassword  = "qwer1234!@#$"
  sshkeys     = <<EOF
  ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7+PcF0yqjmP2yEvt59Ibf/C9h0zNCOHQGwqDJIoSEoYq4wQvEnFL4EnWt5mkZElw7mxrtrIfXBqb9EPEx18w0+RsVdwshN4iBbtJRmelVnK2X4qEGYhvX+XgHM7Z/KLBpEojRZj6fY3oeBwRaM4qstcjPd+F/2EiaivEan2uz4HwRw3YOHa31oqNxQCNJBjjam872xzFasiZ04B8Z1h78BKCm5AVlhPjcrjNqwEuqHqg/YoVJHnprDH08r9mPCkW0JMSJQXxMQZw24P3TGmf5XPlMCqU78txPkSNEWPb5GIVgMzQNMDX5pc4ncnzdJaeosPw6IIm3Lf+1iMxB0DQh root@proxmox1
  EOF
  ipconfig0 = "ip=192.168.24.${100 + count.index}/24,gw=192.168.24.1"

  vga {
    type = "std"
}

  onboot = true

  network {
    model     = "virtio"
    link_down = false
    firewall  = true
    bridge    = "vmbr0"
  }

}

resource "proxmox_vm_qemu" "k3s_worker" {
  count        = var.worker_node_count
  name         = "worker-${count.index + 1}" 
  target_node  = var.proxmox_host
  clone        = var.template_name
  agent        = 1
  os_type      = "126"
  cores        = 2
  sockets      = 2
  memory       = 16384
  bootdisk     = "scsi0"
  scsihw       = "virtio-scsi-pci"  

  disk {
    slot         = "scsi0"
    size         = "200G"
    type         = "disk"
    storage      = var.storage_worker
    backup       = true
    iothread     = true
  }

## disk {
##    slot    = "ide1"
##    type    = "cdrom"
##    storage = "local"
##    size    = "4G"
##    iso  = "local:iso/ubuntu-24.04.1-live-server-amd64.iso"
##  }

  disk {
    slot    = "ide2"
    type    = "cloudinit"
    storage = var.storage_worker
  }

  ciuser      = "systemadmin"
  cipassword  = "qwer1234!@#$"
  sshkeys     = <<EOF
  ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7+PcF0yqjmP2yEvt59Ibf/C9h0zNCOHQGwqDJIoSEoYq4wQvEnFL4EnWt5mkZElw7mxrtrIfXBqb9EPEx18w0+RsVdwshN4iBbtJRmelVnK2X4qEGYhvX+XgHM7Z/KLBpEojRZj6fY3oeBwRaM4qstcjPd+F/2EiaivEan2uz4HwRw3YOHa31oqNxQCNJBjjam872xzFasiZ04B8Z1h78BKCm5AVlhPjcrjNqwEuqHqg/YoVJHnprDH08r9mPCkW0JMSJQXxMQZw24P3TGmf5XPlMCqU78txPkSNEWPb5GIVgMzQNMDX5pc4ncnzdJaeosPw6IIm3Lf+1iMxB0DQh root@proxmox1
  EOF
  ipconfig0 = "ip=192.168.24.${80 + count.index}/24,gw=192.168.24.1"

  vga {
    type = "std"
}

  onboot = true

  network {
    model     = "virtio"
    link_down = false
    firewall  = true
    bridge    = "vmbr0"
  }

}