provider "google" {
  #credentials = "${file("my-gcloud-service-account.json")}"
  project = "${var.gcp_project}"
  region  = "${var.gcp_region}"
  zone    = "${var.gcp_zone}"
}
