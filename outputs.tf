output "fgt0_id" {
  value = google_compute_instance.fgt_vms[0].instance_id
}

output "fgt0_ip" {
  value = google_compute_address.fgt_pub[0].address
}
