data "google_compute_network" "net" {
  name = "default"
}

data "google_compute_subnetwork" "subnet" {
  name   = "default"
}
