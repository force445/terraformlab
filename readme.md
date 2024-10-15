# Terraform Installation

on Linux system using the following commands

```bash
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt update
sudo apt install terraform
terraform --version
```

# Terraform tutorial

create a folder and create a file with the name main.tf and add the following code

```hcl
# tell the terraform which provider to use. the example uses proxmox in this case will use the telmate/proxmox provider
terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      version = "3.0.1-rc4"
    }
  }
}
```
after we declare provider use the command to initialize the provider
```bash
terraform init
```


## configure the proxmox provider
```hcl
provider "proxmox" {
    pm_api_url = "https://proxmox.example.com:8006/api2/json"
    pm_user = "root@pam!exampletokenid"
    #production should use seret from vault
    pm_api_token_secret = data.vault_generic_secret.proxmox.data["pm_api_token_secret"]
    #insecure is not recommended
    pm_tls_insecure = true
    #for debuging purpose
    pm_debug = true
}
```
provider "proxmox" { ... }: This block configures the proxmox provider with the following variables:
pm_api_url: The URL of the Proxmox API.

pm_api_token_id: The API token ID for authentication.

pm_api_token_secret: The API token secret for authentication. (Note: In production, this should be retrieved from a secure source like Vault.)

pm_tls_insecure: A boolean indicating whether to skip TLS verification.

pm_debug: A boolean indicating whether to enable debug mode.

## create a new VM resource configuration
```hcl
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
```
resource "proxmox_vm_qemu" "test_server" { ... }: This block defines a Proxmox VM resource with the following variables:
count: The number of VMs to create.

name: The name of the VM, which includes the count index.

target_node: The Proxmox node where the VM will be created (defined as a variable proxmox_host).

clone: The template to clone for the VM (defined as a variable template_name).

agent: Enables the QEMU guest agent.

os_type: Specifies the OS type, in this case, cloudinit.

cores: The number of CPU cores for the VM.

sockets: The number of CPU sockets for the VM.

memory: The amount of memory (in MB) for the VM.

scsihw: The SCSI controller type.

bootdisk: The boot disk slot.

## Disk Configuration
```hcl
  disk {
    slot         = "scsi0"
    size         = "32G"
    type         = "disk"
    storage      = "local-lvm"
    backup       = true
    iothread     = true
  }
```
disk { ... }: This block defines a disk for the VM with the following variables:
slot: The disk slot.

size: The size of the disk.

type: The type of the disk.

storage: The storage location.

backup: A boolean indicating whether the disk should be included in backups.

iothread: A boolean indicating whether to enable IO threads.

## Cloud-init Disk Configuration
```hcl
  disk {
    slot         = "ide2"
    type         = "cloudinit"
    storage      = "local-lvm"
  }
```
disk { ... }: This block defines a cloud-init disk for the VM with the following variables:

slot: The disk slot.

type: The type of the disk.

storage: The storage location.

## Vm network configuration
```hcl
  network {
    model     = "virtio"
    firewall  = true
    link_down = false
    bridge    = "vmbr0"
  }

  ipconfig0 = "dhcp"
```
network { ... }: This block defines the network interface for the VM with the following variables:

model: Specifies the network interface model. In this case, virtio is used, which is a paravirtualized network driver that provides better performance.

firewall: A boolean indicating whether to enable the firewall for this network interface. Setting this to true enables the firewall.

link_down: A boolean indicating whether the network link should be down initially. Setting this to false ensures that the network link is up.

bridge: Specifies the bridge to which the network interface is connected. In this case, vmbr0 is used, which is a common bridge interface in Proxmox.

ipconfig0 = "dhcp": This line configures the IP address for the first network interface (ipconfig0) to be assigned via DHCP.

## SSH Keys and Cloud-Init Customization
```hcl
  sshkeys = <<EOF
${var.ssh_key}
EOF
  #this is a custom cloud-init file that will be used to configure the VM
  cicustom = "user=local:snippets/user_data_vm-${count.index}.yaml"
}
```
sshkeys: This block defines the SSH keys to be injected into the VM. The <<EOF syntax is used to include a multi-line string, which in this case is the SSH key defined in the variable var.ssh_key.

cicustom: This line specifies a custom cloud-init file to be used for configuring the VM. The cicustom parameter points to a file in the local Proxmox storage (local:snippets/user_data_vm-${count.index}.yaml), which contains additional configuration for the VM.

## var.tf

create var.tf for define input variables. Input variables serve as parameters for your Terraform configuration, allowing you to customize and reuse your configuration with different values without modifying the code itself.

```hcl
variable "ssh_key" {
  default = <<-EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDbI7B6XaZo4MP9/Wg9XpQcfb/joiQsclhMuDFyR5cu5t7+CG2/qW6KYg89mn4FGJzEH+Wd5VIn2xh+9m7t+odckZB2K8GvTxoXDOQLGVn2T8T6IB4XzPfq5FZ8gSHXCe0R3jh9kV7WSZBW8WP7gAYX5w4m120K7SvT9/z0dL/+eucnn/WklZoV8tqfNP+s9yeyWmd7JY3oeQy53GfPOg+rc78/eyCH/5hCI4kbiYLHy0zMn+zyjLd6kFhTm7EyNHblJaPjdwSfCX//waedzIiABB6stByOpYaQ5GiP91hrnCdbCMhMd0EoJ9WE8vSdrH9tc5F84TFck4jhhbmVS6NRrbSdARQSTH/3ZfbHE5g9jdYIwkSA1K3H4ncDd/cjM5mGHYQBbM+f5uX98wW2bS+h9tDld+GE9btka7E4cNPkwDtsinmceqJIjhJuCsihrlLZzLHfyuxQtE9PF+4ZXMjw112nBqrsSviblJ3gLapUUg2YHeMSNEiABWEbhYh9q5U=
EOF
}

variable "proxmox_host" {
    default = "force"
}

variable "template_name" {
    default = "ubuntu-base-template"
}
```
variable "ssh_key":
Purpose: This variable holds the SSH public key that will be injected into the VM for SSH access.
Default Value: The default value is a multi-line string containing an SSH public key. The <<-EOF syntax is used to include the multi-line string.

variable "proxmox_host":
Purpose: This variable specifies the Proxmox node where the VM will be created.
Default Value: The default value is "force".

variable "template_name":
Purpose: This variable specifies the name of the template to clone for the VM.
Default Value: The default value is "ubuntu-base-template".

in the main.tf use var keyword followed by the variable name
ex. var.proxmox_host, var.template_name

## cloud-config custom
The cicustom parameter in the Proxmox VM resource configuration is used to specify a custom cloud-init configuration file for the VM. This allows you to provide additional configuration for the VM during its initialization.

```hcl
cicustom = "user=local:snippets/user_data_vm-${count.index}.yaml"
```
cicustom: This parameter specifies the path to a custom cloud-init configuration file.

user=local:snippets/user_data_vm-${count.index}.yaml: This value indicates that the custom cloud-init file is located in the local Proxmox storage under the snippets directory. The ${count.index} is a placeholder that gets replaced with the current index of the VM being created (starting from 0). This allows you to use different cloud-init files for different VMs if you are creating multiple VMs.

```yml
#cloud-config
users:
  - name: ubuntu
    ssh-authorized-keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDbI7B6XaZo4MP9/Wg9XpQcfb/joiQsclhMuDFyR5cu5t7+CG2/qW6KYg89mn4FGJzEH+Wd5VIn2xh+9m7t+odckZB2K8GvTxoXDOQLGVn2T8T6IB4XzPfq5FZ8gSHXCe0R3jh9kV7WSZBW8WP7gAYX5w4m120K7SvT9/z0dL/+eucnn/WklZoV8tqfNP+s9yeyWmd7JY3oeQy53GfPOg+rc78/eyCH/5hCI4kbiYLHy0zMn+zyjLd6kFhTm7EyNHblJaPjdwSfCX//waedzIiABB6stByOpYaQ5GiP91hrnCdbCMhMd0EoJ9WE8vSdrH9tc5F84TFck4jhhbmVS6NRrbSdARQSTH/3ZfbHE5g9jdYIwkSA1K3H4ncDd/cjM5mGHYQBbM+f5uX98wW2bS+h9tDld+GE9btka7E4cNPkwDtsinmceqJIjhJuCsihrlLZzLHfyuxQtE9PF+4ZXMjw112nBqrsSviblJ3gLapUUg2YHeMSNEiABWEbhYh9q5U= force@force-GL65-9SEK
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    groups: sudo
    shell: /bin/bash
    lock_passwd: false
    passwd: $6$Jf1PFzaroD4ZRKHH$uQv4vSA22RoSjGrXVKbxwpRURqCx.PLqUDSdtqm8eaRPfzh/udhgC1L/H6CSWaNmsqNOrWhLsWBX5/ImnujbQ0
chpasswd:
  list: |
    ubuntu:Force4462
  expire: False
runcmd:
  - apt-get update
  - apt-get install -y unattended-upgrades
  - dpkg-reconfigure -plow unattended-upgrades
  - ufw allow OpenSSH
  - ufw allow 80/tcp
  - ufw allow 443/tcp
```
#cloud-config: Indicates that this file is a cloud-init configuration file.

users: Defines the users to be created on the VM. 

name: The username (ubuntu).
ssh-authorized-keys: The SSH public key to be added to the user's ~/.ssh/authorized_keys file. 

sudo: Grants the user passwordless sudo access. 

groups: Adds the user to the sudo group.    

shell: Specifies the user's default shell (/bin/bash).
lock_passwd: Indicates whether the user's password should be locked (false means the password is not locked). 

passwd: The hashed password for the user. 

chpasswd: Sets the password for the user. 

list: Specifies the username and password in plain text (ubuntu:Force4462). 

expire: Indicates whether the password should expire (False means it does not expire). 

runcmd: A list of commands to run during the first boot.

apt-get update: Updates the package list.

apt-get install -y unattended-upgrades: Installs the unattended-upgrades package.

dpkg-reconfigure -plow unattended-upgrades: Configures the unattended-upgrades package.

ufw allow OpenSSH: Allows SSH traffic through the firewall.

ufw allow 80/tcp: Allows HTTP traffic through the firewall.

ufw allow 443/tcp: Allows HTTPS traffic through the firewall.

## add the cloud-config to proxmox
1. Access Proxmox Server
```bash
ssh root@<proxmox-server-ip>
```
2. Navigate to the Snippets Directory
```bash
cd /var/lib/vz/snippets
```
3. Upload the Cloud-Init file
```bash
scp user_data_vm-0.yaml root@<proxmox-server-ip>:/var/lib/vz/snippets/
```
4. Verify the file is in the correct location
```bash
ls -l /var/lib/vz/snippets
```
## run the terraform
If plan for the first time use
```bash
terraform plan 
```
and then if there is changed happend you must replace the old plan with the new plan otherwise the terraform will use the old plan eventhough you already use terraform plan
```bash
terraform plan -replace=main.tf
```
after this command the terraform will show every parameter if everything is correct use the command
```bash
terraform apply
```
after apply if everything is ok it would show on the terminal like this
```bash
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

proxmox_vm_qemu.test_server[0]: Modifying... [id=force/qemu/101]
proxmox_vm_qemu.test_server[0]: Modifications complete after 2s [id=force/qemu/101]
╷
│ Warning: slot: ide2 size is ignored when type = cloudinit
│ 
│   with proxmox_vm_qemu.test_server[0],
│   on main.tf line 19, in resource "proxmox_vm_qemu" "test_server":
│   19: resource "proxmox_vm_qemu" "test_server" {
│ 
╵
╷
│ Warning: Cloud-init is enabled but no IP config is set
│ 
│   with proxmox_vm_qemu.test_server[0],
│   on main.tf line 19, in resource "proxmox_vm_qemu" "test_server":
│   19: resource "proxmox_vm_qemu" "test_server" {
│ 
│ Cloud-init is enabled in your configuration but no static IP address is set,
│ nor is the DHCP option enabled
╵

Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
```
