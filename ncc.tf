
resource "google_network_connectivity_hub" "this" {
  name          = "${var.prefix}-hub"
  project       = var.project
}
