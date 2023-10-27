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

resource "hcloud_placement_group" "cluster-nodes" {
  name = "cluster-nodes"
  type = "spread"
  labels = var.labels
}

resource "hcloud_server" "node1" {
  name        = "node1"
  image       = "ubuntu-22.04"
  server_type = "cax11"
  ssh_keys    = [hcloud_ssh_key.k8s.id]
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  network {
    network_id = hcloud_network.k8s.id
  }
  placement_group_id = hcloud_placement_group.cluster-nodes.id
  labels = var.labels
}