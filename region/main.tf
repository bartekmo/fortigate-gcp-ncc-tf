data "google_compute_zones" "zones_in_region" {
  region       = var.region
}

locals {

}

locals {
  //TODO: dry this local
  zones        = [
    var.zones[0] != "" ? var.zones[0] : data.google_compute_zones.zones_in_region.names[0],
    var.zones[1] != "" ? var.zones[1] : data.google_compute_zones.zones_in_region.names[1],
    var.zones[1] != "" ? var.zones[2] : data.google_compute_zones.zones_in_region.names[2]
  ]

  zones_short  = [
    replace( replace( replace( replace( replace(local.zones[0], "us-", "us"), "europe-", "eu"), "australia-", "au" ), "northamerica-", "na"), "southamerica-", "sa"),
    replace( replace( replace( replace( replace(local.zones[1], "us-", "us"), "europe-", "eu"), "australia-", "au" ), "northamerica-", "na"), "southamerica-", "sa"),
    replace( replace( replace( replace( replace(local.zones[2], "us-", "us"), "europe-", "eu"), "australia-", "au" ), "northamerica-", "na"), "southamerica-", "sa")
  ]

  region_short = replace( replace( replace( replace( replace( var.region, "us-", "us"), "europe-", "eu"), "australia-", "au" ), "northamerica-", "na"), "southamerica-", "sa")
}


resource "google_compute_subnetwork" "spoke" {
  name = "${var.prefix}-sb-hub-${var.region_short}"
  network = var.hub_vpc_url
  region = var.region
  ip_cidr_range = var.ip_cidr_range
}
