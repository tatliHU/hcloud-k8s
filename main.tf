terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
}

provider "hcloud" {
  token = "${var.hcloud_token}"
}

locals {
  nodes = var.masters + var.workers
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
  labels = var.labels
}

resource "hcloud_placement_group" "cluster_nodes" {
  name = "cluster-nodes"
  type = "spread"
  labels = var.labels
}

resource "hcloud_server" "cluster_nodes" {
  count        = local.nodes
  name         = format("node%s", count.index)
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
  labels = var.labels
}