resource "google_compute_address" "cr_nic0" {
  name          = "${var.prefix}-addr-cr-nic0"
  address_type  = "INTERNAL"
  subnetwork    = google_compute_subnetwork.hub.self_link
}

resource "google_compute_address" "cr_nic1" {
  name          = "${var.prefix}-addr-cr-nic1"
  address_type  = "INTERNAL"
  subnetwork    = google_compute_subnetwork.hub.self_link
}

resource "google_compute_router" "this" {
  name          = "${var.prefix}-cr-${local.region_short}"
  network       = google_compute_network.hub.self_link
  bgp {
    asn               = var.ncc_asn
    advertise_mode    = "CUSTOM"
    advertised_groups = [
      "ALL_SUBNETS"
    ]
    dynamic "advertised_ip_ranges" {
      for_each  = local.wrkld_cidr_ranges

      content {
        range   = advertised_ip_ranges.key
      }
    }
  }
}

resource "google_network_connectivity_hub" "this" {
  name          = "${var.prefix}-hub"
  project       = var.project
}

resource "google_network_connectivity_spoke" "this" {
  name          = "${var.prefix}-spoke-${var.region}"
  location      = var.region
  hub           = google_network_connectivity_hub.this.id

  linked_router_appliance_instances {
    dynamic "instances" {
      for_each                 = range(var.cnt)
      content {
        virtual_machine        = google_compute_instance.fgt_vms[instances.key].self_link
        ip_address             = google_compute_address.fgt_priv[instances.key].address
      }
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
    create            = templatefile( "cr-add-interfaces.sh.tftpl",
      {
        CR_NAME       = google_compute_router.this.name
        SUBNET_NAME   = google_compute_subnetwork.hub.name
        REGION        = var.region
        PROJECT       = var.project
        IP_NIC0       = google_compute_address.cr_nic0.address
        IP_NIC1       = google_compute_address.cr_nic1.address
      }
    )
  }
  provisioner "local-exec" {
    command = self.triggers.create
  }
}

/*
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
*/
resource "null_resource" "bgp_peers" {
  depends_on = [
    null_resource.ncc_interfaces,
    google_compute_network_peering.spoke_to_hub
  ]
  triggers = {
    create = join( "", [
      for i in range(var.cnt) : <<EOF
      gcloud compute routers add-bgp-peer ${google_compute_router.this.name} \
        --peer-name=${google_compute_instance.fgt_vms[i].name}-nic0 \
        --interface=${google_compute_router.this.name}-nic0 \
        --peer-ip-address=${google_compute_address.fgt_priv[i].address} \
        --peer-asn=${var.fgt_asn} \
        --instance=${google_compute_instance.fgt_vms[i].name} \
        --instance-zone=${google_compute_instance.fgt_vms[i].zone} \
        --region=${var.region} \
        --project=${var.project}

      gcloud compute routers add-bgp-peer ${google_compute_router.this.name} \
        --peer-name=${google_compute_instance.fgt_vms[i].name}-nic1 \
        --interface=${google_compute_router.this.name}-nic1 \
        --peer-ip-address=${google_compute_address.fgt_priv[i].address} \
        --peer-asn=${var.fgt_asn} \
        --instance=${google_compute_instance.fgt_vms[i].name} \
        --instance-zone=${google_compute_instance.fgt_vms[i].zone} \
        --region=${var.region} \
        --project=${var.project}
EOF
    ])
  }
  provisioner "local-exec" {
    command = self.triggers.create
  }
}
