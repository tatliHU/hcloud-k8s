terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
    time = {
      source = "hashicorp/time"
    }
  }
}

provider "hcloud" {
  token = "${var.hcloud_token}"
}

resource "hcloud_ssh_key" "k8s" {
  name       = "k8s-instance-key"
  public_key = file("${var.public_key_file}")
  labels     = var.labels
}

resource "hcloud_network" "k8s" {
  name     = "k8s-instance-network"
  ip_range = "10.0.0.0/24"
  labels     = var.labels
}

resource "hcloud_network_subnet" "cluster" {
  network_id   = hcloud_network.k8s.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.0.0/26"
}

resource "hcloud_firewall" "allow_inbound" {
  name = "k8s-allow-inbound"
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = 22
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    direction = "out"
    protocol  = "tcp"
    port      = 22
    destination_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "80"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    direction = "out"
    protocol  = "tcp"
    port      = "80"
    destination_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    direction = "out"
    protocol  = "tcp"
    port      = "443"
    destination_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
    rule {
    direction = "in"
    protocol  = "tcp"
    port      = "6443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    direction = "out"
    protocol  = "tcp"
    port      = "6443"
    destination_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  labels = var.labels
}

resource "hcloud_placement_group" "cluster_nodes" {
  name = "cluster-nodes"
  type = "spread"
  labels = var.labels
}

data "template_file" "init_masters" {
  template = "${file("${path.module}/cloud-init.yaml.template")}"
  vars = {
    ssh_key = hcloud_ssh_key.k8s.public_key
    command = "sh -"
  }
}

resource "hcloud_server" "master_nodes" {
  count        = var.masters
  name         = format("master%s", count.index)
  image        = var.instance_image
  server_type  = var.instance_type
  ssh_keys     = [hcloud_ssh_key.k8s.id]
  firewall_ids = [hcloud_firewall.allow_inbound.id]
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  network {
    network_id = hcloud_network.k8s.id
  }
  placement_group_id = hcloud_placement_group.cluster_nodes.id
  user_data          = data.template_file.init_masters.rendered
  labels             = merge(var.labels, {nodeType = "master"})
}

resource "time_sleep" "wait_for_masters" {
  create_duration = "30s"
  depends_on      = [hcloud_server.master_nodes]
}

# fetch k3s token to connect more nodes to the cluster
resource "null_resource" "k3s_token" {
  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${hcloud_server.master_nodes[0].ipv4_address}:/var/lib/rancher/k3s/server/token ."
  }
  depends_on = [time_sleep.wait_for_masters]
}

data "local_file" "k3s_token" {
  filename   = "${path.module}/token"
  depends_on = [null_resource.k3s_token]
}

data "template_file" "init_workers" {
  template = "${file("${path.module}/cloud-init.yaml.template")}"
  vars = {
    ssh_key = hcloud_ssh_key.k8s.public_key
    command = "K3S_URL=https://${hcloud_server.master_nodes[0].ipv4_address}:6443 K3S_TOKEN=${trimspace(data.local_file.k3s_token.content)} sh -"
  }
}

resource "hcloud_server" "worker_nodes" {
  count        = var.workers
  name         = format("worker%s", count.index)
  image        = var.instance_image
  server_type  = var.instance_type
  ssh_keys     = [hcloud_ssh_key.k8s.id]
  firewall_ids = [hcloud_firewall.allow_inbound.id]
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  network {
    network_id = hcloud_network.k8s.id
  }
  placement_group_id = hcloud_placement_group.cluster_nodes.id
  user_data          = data.template_file.init_workers.rendered
  labels             = merge(var.labels, {nodeType = "worker"})
}

resource "hcloud_volume" "worker" {
  count     = var.workers
  name      = format("k8s-worker%s", count.index)
  size      = var.worker_volume_size
  location  = "hel1"
  format    = "ext4"
}

resource "hcloud_volume_attachment" "worker" {
  count     = var.workers
  volume_id = hcloud_volume.worker[count.index].id
  server_id = hcloud_server.worker_nodes[count.index].id
  automount = true
}