data "template_file" "startup_script" {
  template = <<EOF
apt-get update
apt-get install -y docker.io docker-compose
usermod -aG docker ubuntu

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

apt-get install -y apt-transport-https
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubectl

export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
apt-get update && apt-get install -y google-cloud-sdk
EOF
}

data "template_file" "enable_kubectl_script" {
  template = <<EOF
#!/bin/sh
gcloud config configurations create training --activate
gcloud config set core/project $${project}
gcloud config set compute/region $${region}
gcloud config set compute/zone $${zone}
gcloud auth activate-service-account --key-file /tmp/service_account.json
gcloud container clusters get-credentials $${cluster_name}
EOF

  vars {
    cluster_name = "${var.global_prefix}${var.cluster_name}"
    zone         = "${var.gcp_zone}"
    region       = "${var.gcp_region}"
    project      = "${var.gcp_project}"
  }
}

resource "google_compute_instance" "compute-inst" {
  zone = "${var.gcp_zone}"
  name = "${var.global_prefix}training-${count.index}"
  machine_type = "${var.bastion_machine_type}"
  count   = "${var.bastion_count}"
  boot_disk {
    initialize_params {
      image = "ubuntu-1604-xenial-v20181004"
    }
  }
  network_interface {
    subnetwork = "${google_compute_subnetwork.subnet.self_link}"
    access_config {
    }
  }
  metadata {
    sshKeys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
    startup-script = "${data.template_file.startup_script.rendered}"
  }
  provisioner "file" {
    source      = "${var.gce_service_account_key}"
    destination = "/tmp/service_account.json"
    connection {
        type = "ssh"
        user = "${var.gce_ssh_user}"
        private_key = "${file(var.gce_ssh_private_key_file)}"
    }
  }
  provisioner "file" {
    content     = "${data.template_file.enable_kubectl_script.rendered}"
    destination = "/tmp/enable_kubectl.sh"
    connection {
        type = "ssh"
        user = "${var.gce_ssh_user}"
        private_key = "${file(var.gce_ssh_private_key_file)}"
    }
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