data "google_compute_image" "fgt_image" {
  project                = "fortigcp-project-001"
  family                 = var.fgt_firmware_family
}

data "google_compute_default_service_account" "default" {
  #project      = var.project
}

resource "google_compute_address" "fgt_priv" {
  count                  = var.cnt
  name                   = "${var.prefix}-addr-fgt${count.index+1}-${local.zones_short[count.index]}"
  address_type           = "INTERNAL"
  subnetwork             = google_compute_subnetwork.spoke.self_link
  region                 = var.region
}

resource "google_compute_address" "fgt_pub" {
  count                  = var.cnt
  name                   = "${var.prefix}-eip-fgt${count.index+1}-${local.zones_short[count.index]}"
  address_type           = "EXTERNAL"
  region                 = var.region
  #project                = var.project
}

resource "google_compute_disk" "logdisks" {
  count                  = var.cnt

  name                   = "${var.prefix}disk-logdisk${count.index+1}-${local.zones_short[count.index]}"
  size                   = 30
  type                   = "pd-ssd"
  zone                   = local.zones[count.index]
  #project                = var.project
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
    user-data            = templatefile( "${path.module}/fgt-config.tftpl",
      {
        hostname = "${var.prefix}vm-fgt${count.index+1}-${local.zones_short[count.index]}"
        healthcheck_port = var.healthcheck_port
        port1_addr       = google_compute_address.fgt_priv[count.index].address
        port1_gw         = google_compute_subnetwork.spoke.gateway_address
        fgt_asn          = var.fgt_asn
        ncc_asn          = var.ncc_asn
        cr_nic0          = google_compute_address.cr_nic0.address
        cr_nic1          = google_compute_address.cr_nic1.address
        elb_pub          = google_compute_address.elb_pub.address
        fmg_serial       = var.fmg_serial
        fmg_ip           = var.fmg_ip
      }
    )
    license              = fileexists(var.license_files[count.index]) ? file(var.license_files[count.index]) : null
  }

  network_interface {
    subnetwork           = google_compute_subnetwork.spoke.id
    network_ip           = google_compute_address.fgt_priv[count.index].address
    access_config {
      nat_ip             = google_compute_address.fgt_pub[count.index].address
    }
  }
}
