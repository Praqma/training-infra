provider "google" {
  credentials = "${file("/home/mvl/.config/gcloud/test-proj2-218313-df1417b8307d.json")}"
  project = "${var.gcp_project}"
  region  = "${var.gcp_region}"
  zone    = "${var.gcp_zone}"
}
