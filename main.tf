terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      version = "3.0.1-rc4"
    }
  }
}

provider "proxmox" {
  pm_api_url        = "https://192.168.122.200:8006/api2/json"
  pm_api_token_id   = "root@pam!token_id"
  pm_api_token_secret = "552f1b22-3eff-4046-8436-af5369f1d4c0"
  pm_tls_insecure   = true
  pm_debug = true
}

resource "proxmox_vm_qemu" "test_server" {
  count        = 1 
  name         = "test-vm-${count.index + 1}" 
  target_node  = var.proxmox_host
  clone        = var.template_name
  agent        = 1
  os_type      = "cloudinit"
  cores        = 2
  sockets      = 1
  memory       = 2048
  scsihw       = "virtio-scsi-pci"
  bootdisk     = "scsi0"

  disk {
    slot         = "scsi0"
    size         = "32G"
    type         = "disk"
    storage      = "local-lvm"
    backup       = true
    iothread     = true
  }

  disk {
    slot         = "ide2"
    type         = "cloudinit"
    storage      = "local-lvm"
  }

  network {
    model     = "virtio"
    firewall  = true
    link_down = false
    bridge    = "vmbr0"
  }

  ipconfig0 = "dhcp"
  
  sshkeys = <<EOF
${var.ssh_key}
EOF

  cicustom = "user=local:snippets/user_data_vm-${count.index}.yaml"
}
  