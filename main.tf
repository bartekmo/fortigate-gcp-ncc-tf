data "google_compute_image" "fgt_image" {
  project = "fortigcp-project-001"
  family  = "fortigate-70-byol"
}

data "google_compute_zones" "zones_in_region" {
  region         = var.region
  project = var.project
}

data "google_compute_default_service_account" "default" {
  project = var.project
}

locals {
  zones = [
    var.zones[0] != "" ? var.zones[0] : data.google_compute_zones.zones_in_region.names[0],
    var.zones[1] != "" ? var.zones[1] : data.google_compute_zones.zones_in_region.names[1]
  ]
}

locals {
  region_short   = replace( replace( replace( replace(var.region, "europe-", "eu"), "australia", "au" ), "northamerica", "na"), "southamerica", "sa")
  zones_short    = [
    replace( replace( replace( replace(local.zones[0], "europe-", "eu"), "australia", "au" ), "northamerica", "na"), "southamerica", "sa"),
    replace( replace( replace( replace(local.zones[1], "europe-", "eu"), "australia", "au" ), "northamerica", "na"), "southamerica", "sa")
  ]
}

resource "google_compute_network" "hub" {
  name = "${var.prefix}-vpc-hub"
  auto_create_subnetworks = false
  project = var.project
}

resource "google_compute_subnetwork" "hub" {
  name = "${var.prefix}-sb-hub-${local.region_short}"
  network = google_compute_network.hub.self_link
  region = var.region
  ip_cidr_range = "172.20.0.0/24"
}

resource "google_compute_route" "fgt_out" {
  name       = "${var.prefix}-rt-hub-fgt-default"
  dest_range = "0.0.0.0/0"
  network    = google_compute_network.hub.self_link
  priority   = 90
  next_hop_gateway = "default-internet-gateway"
  tags = ["fgt"]
}

resource "google_compute_route" "default_out" {
  name       = "${var.prefix}-rt-hub-default"
  dest_range = "0.0.0.0/0"
  network    = google_compute_network.hub.self_link
  priority   = 900
  next_hop_instance = google_compute_instance.fgt_vms[0].self_link
}

resource "google_compute_firewall" "allow-admin" {
  name                   = "${var.prefix}-fw-allow-admin"
  network                = google_compute_network.hub.self_link
  target_tags            = ["fgt"]
  source_ranges          = var.admin_acl

  allow {
    protocol             = "all"
  }
}

resource "google_compute_address" "cr_nic0" {
  name = "${var.prefix}-addr-cr-nic0"
  address_type = "INTERNAL"
  subnetwork = google_compute_subnetwork.hub.self_link
}

resource "google_compute_address" "cr_nic1" {
  name = "${var.prefix}-addr-cr-nic1"
  address_type = "INTERNAL"
  subnetwork = google_compute_subnetwork.hub.self_link
}

resource "google_compute_address" "fgt_priv" {
  count = var.cnt
  name = "${var.prefix}-addr-fgt${count.index+1}"
  address_type = "INTERNAL"
  subnetwork = google_compute_subnetwork.hub.self_link
}

resource "google_compute_address" "fgt_pub" {
  count = var.cnt
  name = "${var.prefix}-eip-fgt${count.index+1}"
  address_type = "EXTERNAL"
  project = var.project
}

resource "google_compute_disk" "logdisks" {
  count                  = var.cnt

  name                   = "${var.prefix}disk-logdisk${count.index+1}-${local.zones_short[count.index]}"
  size                   = 30
  type                   = "pd-ssd"
  zone                   = local.zones[count.index]
  project = var.project
}

resource "google_compute_instance" "fgt_vms" {
  count = var.cnt

  zone                   = local.zones[count.index]
  name                   = "${var.prefix}vm-fgt${count.index+1}-${local.zones_short[count.index]}"
  machine_type           = var.machine_type
  can_ip_forward         = true
  tags                   = ["fgt"]

  boot_disk {
    initialize_params {
      image              = data.google_compute_image.fgt_image.self_link
    }
  }
  attached_disk {
    source               = google_compute_disk.logdisks[count.index].name
  }

  service_account {
    email                = (var.service_account != "" ? var.service_account : data.google_compute_default_service_account.default.email)
    scopes               = ["cloud-platform"]
  }

  metadata = {
    user-data            = templatefile( "fgt-config.tftpl",
      {
        hostname = "${var.prefix}vm-fgt${count.index+1}-${local.zones_short[count.index]}"
        healthcheck_port = var.healthcheck_port
        port1_addr       = google_compute_address.fgt_priv[count.index].address
        port1_gw         = google_compute_subnetwork.hub.gateway_address
        fgt_asn          = var.fgt_asn
        ncc_asn          = var.ncc_asn
        cr_nic0          = google_compute_address.cr_nic0.address
        cr_nic1          = google_compute_address.cr_nic1.address
        elb_pub = "1.2.3.4"
      }
    )
    license              = fileexists(var.license_files[count.index]) ? file(var.license_files[count.index]) : null
  }

  network_interface {
    subnetwork           = google_compute_subnetwork.hub.id
    network_ip           = google_compute_address.fgt_priv[count.index].address
    access_config {
      nat_ip             = google_compute_address.fgt_pub[count.index].address
    }
  }
}

resource "google_compute_router" "this" {
  name = "${var.prefix}-cr-${local.region_short}"
  network = google_compute_network.hub.self_link
  bgp {
    asn = var.ncc_asn
    advertise_mode = "DEFAULT"
  }
}

resource "google_network_connectivity_hub" "this" {
  name = "${var.prefix}-hub"
  project = var.project
}

resource "google_network_connectivity_spoke" "this" {
  name = "${var.prefix}-spoke-${var.region}"
  location = var.region
  hub = google_network_connectivity_hub.this.id
  linked_router_appliance_instances {
    instances {
      virtual_machine = google_compute_instance.fgt_vms[0].self_link
      ip_address = google_compute_address.fgt_priv[0].address
    }
    site_to_site_data_transfer = false
  }
}


resource "null_resource" "ncc_interfaces" {
  depends_on = [
    google_compute_address.cr_nic0,
    google_compute_address.cr_nic1,
    google_compute_subnetwork.hub,
    google_compute_router.this
  ]
  triggers = {
    create = templatefile( "cr-add-interfaces.sh.tftpl",
      {
        CR_NAME = google_compute_router.this.name
        SUBNET_NAME = google_compute_subnetwork.hub.name
        REGION = var.region
        PROJECT = var.project
        IP_NIC0 = google_compute_address.cr_nic0.address
        IP_NIC1 = google_compute_address.cr_nic1.address
      }
    )
  }
  provisioner "local-exec" {
    command = self.triggers.create
  }
}


resource "null_resource" "bgp_peers" {
  count = var.cnt

  depends_on = [
    null_resource.ncc_interfaces
  ]
  triggers = {
    create = templatefile( "cr-add-bgp-peer.sh.tftpl",
      {
        fgt_asn = var.fgt_asn,
        fgt_name = google_compute_instance.fgt_vms[count.index].name
        fgt_address = google_compute_address.fgt_priv[count.index].address
        fgt_zone = google_compute_instance.fgt_vms[count.index].zone
        cr_name = google_compute_router.this.name
        region = var.region
        project = var.project
      }
    )
  }
  provisioner "local-exec" {
    command = self.triggers.create
  }
}
