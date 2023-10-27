output ip {
  description = "IPs of the nodes."
  value       = hcloud_server.cluster_nodes[*].ipv4_address
}
