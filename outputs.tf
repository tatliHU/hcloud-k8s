output master_ips {
  description = "IPs of the master nodes."
  value       = hcloud_server.master_nodes[*].ipv4_address
}

output worker_ips {
  description = "IPs of the worker nodes."
  value       = hcloud_server.worker_nodes[*].ipv4_address
}

output volume_mount_path {
  description = "Path to volume mount"
  value       = {
    for i in range(var.workers):
        hcloud_server.worker_nodes[i].name => hcloud_volume.worker[i].linux_device
    }
}
