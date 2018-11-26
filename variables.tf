variable "global_prefix" {
  default = ""
}

variable "gcp_service_account_key" {
  description = "The service account used to create all resource. The service account should have the roles Compute Admin, Kubernetes Engine Admin and Service Account User"
}

variable "gcp_project" {
  description = "The Google Cloud Platform project to use for created resources"
}

variable "gcp_region" {
  description = "The Google Cloud Platform region to use for created resources"
  default = "europe-west1"
}

variable "gcp_zone" {
  description = "The Google Cloud Platform zone to use for created resources"
  default = "europe-west1-b"
}

variable "cluster_name" {
  default = "training-cluster"
}

variable "initial_worker_node_count" {
  default = 3
}

variable "source_ip_cidr" {
  description = "The source CIDR from where the training network access originates.  Typically the /32 external NAT address of the training network. Note that this is a list"
  default = [ "0.0.0.0/0" ]
}

variable "bastion_ports" {
  default = ["5000", "8000", "8080"]
}

variable "cluster_ports" {
  default = ["3000", "30000-32767"]
}

variable "gce_ssh_user" {
  default = "ubuntu"
}

variable "gce_ssh_pub_key_file" {
  default = "testkey.pub"
}

variable "gce_ssh_private_key_file" {
  default = "testkey"
}

variable "bastion_machine_type" {
  default = "g1-small"
}

variable "bastion_count" {
  default = 1
}
