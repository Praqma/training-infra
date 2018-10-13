resource "google_container_cluster" "k8cluster" {
  name               = "${var.cluster_name}"
  zone               = "${var.gcp_zone}"
  initial_node_count = "${var.initial_worker_node_count}"
  network            = "${data.google_compute_network.net.name}"
  subnetwork         = "${data.google_compute_subnetwork.subnet.name}"
  addons_config {
    kubernetes_dashboard {
      disabled = false
    }
    #http_load_balancing {
    #  # Disable GKE ingress controller
    #  disabled = true
    #}
  }

  node_config {
    tags = [ "kubernetes" ]
  }
}

resource "google_compute_firewall" "fw-k8s-eph-ports" {
  name    = "tcp-allow-ephemeral-ports"
  network = "${data.google_compute_network.net.name}"

  allow {
    protocol = "tcp"
    ports    = ["30000-32767"]
  }
  source_ranges = "${var.source_ip_cidr}"
  target_tags = [ "kubernetes" ]
}
