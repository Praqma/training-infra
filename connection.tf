provider "google" {
  version = "v1.18.0"
  credentials = "${file(var.gcp_service_account_key)}"
  project = "${var.gcp_project_id}"
  region  = "${var.gcp_region}"
  zone    = "${var.gcp_zone}"
}
