variable "ssh_key" {
  default = <<-EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDbI7B6XaZo4MP9/Wg9XpQcfb/joiQsclhMuDFyR5cu5t7+CG2/qW6KYg89mn4FGJzEH+Wd5VIn2xh+9m7t+odckZB2K8GvTxoXDOQLGVn2T8T6IB4XzPfq5FZ8gSHXCe0R3jh9kV7WSZBW8WP7gAYX5w4m120K7SvT9/z0dL/+eucnn/WklZoV8tqfNP+s9yeyWmd7JY3oeQy53GfPOg+rc78/eyCH/5hCI4kbiYLHy0zMn+zyjLd6kFhTm7EyNHblJaPjdwSfCX//waedzIiABB6stByOpYaQ5GiP91hrnCdbCMhMd0EoJ9WE8vSdrH9tc5F84TFck4jhhbmVS6NRrbSdARQSTH/3ZfbHE5g9jdYIwkSA1K3H4ncDd/cjM5mGHYQBbM+f5uX98wW2bS+h9tDld+GE9btka7E4cNPkwDtsinmceqJIjhJuCsihrlLZzLHfyuxQtE9PF+4ZXMjw112nBqrsSviblJ3gLapUUg2YHeMSNEiABWEbhYh9q5U=
EOF
}

variable "proxmox_host" {
    default = "proxmox1"
}

variable "template_name" {
    default = "ubuntu-cloud-test"
}

variable "control_plane_count" {
  description = "Number of control plane nodes"
  default     = 2
}

variable "worker_node_count" {
  description = "Number of worker nodes"
  default     = 3
}

variable "storage_control_plane" {
  description =  "Name of control plane's storage"
  default     =  "data"
}

variable "storage_worker" {
  description = "Name of worker's storage"
  default     = "disk-f"
}
