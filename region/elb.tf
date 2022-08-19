resource "google_compute_address" "elb_pub" {
  name                   = "${var.prefix}-eip-elb-${local.region_short}"
  address_type           = "EXTERNAL"
  region                 = var.region
  #project                = var.project
}

resource "google_compute_region_health_check" "health_check" {
  name                   = "${var.prefix}healthcheck-http${var.healthcheck_port}-${local.region_short}"
  region                 = var.region
  timeout_sec            = 2
  check_interval_sec     = 2

  http_health_check {
    port                 = var.healthcheck_port
  }
}

resource "google_compute_instance_group" "fgt_umigs" {
  count                  = var.cnt

  name                   = "${var.prefix}umig${count.index}-${local.zones_short[count.index]}"
  zone                   = google_compute_instance.fgt_vms[count.index].zone
  instances              = [google_compute_instance.fgt_vms[count.index].self_link]
}

resource "google_compute_forwarding_rule" "elb_frule" {
  name                   = "${var.prefix}-fwd-elb-${local.region_short}"
  region                 = var.region
  ip_address             = google_compute_address.elb_pub.self_link
  ip_protocol            = "L3_DEFAULT"
  all_ports              = true
  load_balancing_scheme  = "EXTERNAL"
  backend_service        = google_compute_region_backend_service.elb_bes.self_link
}

resource "google_compute_region_backend_service" "elb_bes" {
  name                   = "${var.prefix}-bes-elb-${local.region_short}"
  region                 = var.region
  load_balancing_scheme  = "EXTERNAL"
  protocol               = "UNSPECIFIED"

  dynamic "backend" {
    for_each             = google_compute_instance_group.fgt_umigs[*].self_link

    content {
      group              = backend.value
    }
  }
  health_checks          = [google_compute_region_health_check.health_check.self_link]
}
