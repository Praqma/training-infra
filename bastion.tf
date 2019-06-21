data "template_file" "startup_script" {
  template = "${file("${path.module}/startup-script.tpl")}"

  vars = {
     cluster_name = "${var.global_prefix}${var.cluster_name}"
     zone         = "${var.gcp_zone}"
     region       = "${var.gcp_region}"
     project      = "${var.gcp_project_id}"
     extra_bootstrap_cmds = "${var.extra_bootstrap_cmds}"
  }
}

resource "google_compute_instance" "compute-inst" {
  zone = "${var.gcp_zone}"
  name = "${var.global_prefix}training-${count.index + 1}"
  machine_type = "${var.bastion_machine_type}"
  count   = "${var.bastion_count}"
  service_account {
    email = "${google_service_account.account.email}"
    scopes = [ "cloud-platform" ]
  }
  boot_disk {
    initialize_params {
      image = "${var.bastion_image_name}"
    }
  }
  network_interface {
    subnetwork = "${google_compute_subnetwork.subnet.self_link}"
    access_config {
    }
  }
  metadata = {
    sshKeys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
    startup-script = "${data.template_file.startup_script.rendered}"
  }

  tags = [ "bastion" ]
}

resource "google_compute_firewall" "fw-ssh" {
  name    = "${var.global_prefix}tcp-ssh"
  network = "${google_compute_network.net.self_link}"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = "${var.source_ip_cidr}"
  target_tags = [ "bastion" ]
}

resource "google_compute_firewall" "fw-user-ports" {
  name    = "${var.global_prefix}tcp-user-ports"
  network = "${google_compute_network.net.self_link}"
  allow {
    protocol = "tcp"
    ports    = "${var.bastion_ports}"
  }
  source_ranges = "${var.source_ip_cidr}"
  target_tags = [ "bastion" ]
}

output "instance_ips" {
  value = ["${google_compute_instance.compute-inst.*.network_interface.0.access_config.0.nat_ip}"]
}
