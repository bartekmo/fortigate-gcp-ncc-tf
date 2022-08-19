data "google_compute_zones" "zones_in_region" {
  region       = var.region
  project      = var.project
}

data "google_compute_default_service_account" "default" {
  project      = var.project
}

locals {
  zones        = [
    var.zones[0] != "" ? var.zones[0] : data.google_compute_zones.zones_in_region.names[0],
    var.zones[1] != "" ? var.zones[1] : data.google_compute_zones.zones_in_region.names[1]
  ]
}

locals {
  region_short = replace( replace( replace( replace(var.region, "europe-", "eu"), "australia", "au" ), "northamerica", "na"), "southamerica", "sa")
  zones_short  = [
    replace( replace( replace( replace(local.zones[0], "europe-", "eu"), "australia", "au" ), "northamerica", "na"), "southamerica", "sa"),
    replace( replace( replace( replace(local.zones[1], "europe-", "eu"), "australia", "au" ), "northamerica", "na"), "southamerica", "sa")
  ]
  regions_short = [ for region in var.regions: replace( replace( replace( replace( replace(region, "us-", "us"), "europe-", "eu"), "australia-", "au" ), "northamerica-", "na"), "southamerica-", "sa")]
}

module "region" {
  for_each = toset(var.regions)
  source = "./region"

  prefix = var.prefix
  region = each.value
  region_short = local.regions_short[ index(var.regions, each.value)]
  ip_cidr_range = cidrsubnet( var.hub_cidr_range, var.hub_subnet_bitmask, index(var.regions, each.value))
  hub_vpc_url = google_compute_network.hub.self_link
  fgt_asn = var.fgt_asn
  ncc_hub_id = google_network_connectivity_hub.this.id
  project = var.project
  cnt = var.cnt

  depends_on = [
    google_compute_network_peering.spoke_to_hub
  ]
}

#module "branches" {
#  count = var.branch_cnt
#  source = "./branch"

#  prefix = "${var.prefix}-branch${count.index}"
#  region = each.value
#  ip_cidr_range = "192.168.${count.index}.0/24"
#}
