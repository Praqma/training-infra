resource "google_service_account" "account" {
  account_id   = "${var.global_prefix}k8s-trainee"
  display_name = "${var.global_prefix}k8s-trainee"
}

#resource "google_service_account_key" "key" {
#  service_account_id = "${google_service_account.account.id}"
#  public_key_type    = "TYPE_X509_PEM_FILE"
#}

resource "google_project_iam_member" "project" {
  project = "${var.gcp_project_id}"
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.account.email}"
}

#output "dev_service_account_key" {
#  value = "${google_service_account_key.key.private_key}"
#}
