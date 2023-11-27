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

resource "null_resource" "kubeconfig" {
  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${hcloud_server.master_nodes[0].ipv4_address}:/etc/rancher/k3s/k3s.yaml ./k3s.yaml"
  }
  depends_on = [time_sleep.wait_for_masters]
}