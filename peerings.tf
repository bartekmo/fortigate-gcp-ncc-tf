data "google_compute_network" "spokes" {
  count = length(var.wrkld_vpcs)
  name     = var.wrkld_vpcs[count.index].name
  project  = var.wrkld_vpcs[count.index].project
}

data "google_compute_subnetwork" "spoke_subnets" {
  for_each             = toset(flatten(concat( data.google_compute_network.spokes[*].subnetworks_self_links)))
  self_link            = each.key
}

locals {
  wrkld_cidr_ranges = toset([for subnet in data.google_compute_subnetwork.spoke_subnets : subnet.ip_cidr_range])
}

resource "google_compute_network_peering" "hub_to_spoke" {
  count = length(data.google_compute_network.spokes)

  name                 = "peer-fgthub-to-${var.wrkld_vpcs[count.index].project}-${var.wrkld_vpcs[count.index].name}"
  network              = google_compute_network.hub.id
  peer_network         = data.google_compute_network.spokes[count.index].id
  export_custom_routes = true
  depends_on           = [
# TODO: dependencies within a series of spokes
  ]
}

resource "google_compute_network_peering" "spoke_to_hub" {
  count = length(data.google_compute_network.spokes)

  name                 = "peer-${var.wrkld_vpcs[count.index].project}-${var.wrkld_vpcs[count.index].name}-to-fgthub"
  network              = data.google_compute_network.spokes[count.index].id
  peer_network         = google_compute_network.hub.id
  import_custom_routes = true
  depends_on           = [
    google_compute_network_peering.hub_to_spoke
  ]
}
