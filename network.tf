resource "google_compute_network" "hub" {
  name = "${var.prefix}-vpc-hub"
  auto_create_subnetworks = false
  delete_default_routes_on_create = true
  project = var.project
}

#resource "google_compute_subnetwork" "spokes" {
#  for_each = toset(var.regions)

#  name = "${var.prefix}-sb-hub-${local.regions_short[ index(var.regions, each.value)]}"
#  network = google_compute_network.hub.self_link
#  region = each.value
#  ip_cidr_range = cidrsubnet( var.hub_cidr_range, var.hub_subnet_bitmask, index(var.regions, each.value))
#}

resource "google_compute_route" "fgt_out" {
  name       = "${var.prefix}-rt-hub-fgt-default"
  dest_range = "0.0.0.0/0"
  network    = google_compute_network.hub.self_link
  priority   = 10
  next_hop_gateway = "default-internet-gateway"
  tags = ["fgt"]
}

## replaced by BGP advertisement from FGT
#
#resource "google_compute_route" "default_out" {
#  name       = "${var.prefix}-rt-hub-default"
#  dest_range = "0.0.0.0/0"
#  network    = google_compute_network.hub.self_link
#  priority   = 900
#  next_hop_instance = google_compute_instance.fgt_vms[0].self_link
#}

resource "google_compute_firewall" "allow-admin" {
  name                   = "${var.prefix}-fw-allow-admin"
  network                = google_compute_network.hub.self_link
  target_tags            = ["fgt"]
  source_ranges          = var.admin_acl

  allow {
    protocol             = "all"
  }
}

resource "google_compute_firewall" "allow_in" {
  name                   = "${var.prefix}-fw-allow-all-in"
  network                = google_compute_network.hub.self_link
  source_ranges          = ["0.0.0.0/0"]

  allow {
    protocol             = "all"
  }
}
