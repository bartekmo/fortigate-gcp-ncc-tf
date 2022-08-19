variable "region" {
  type = string
}

variable "zones" {
  type = list(string)
  default = ["","",""]
  description = "List of zones to deploy to. If not provided zones will be pulled automatically from region"
}

variable "prefix" {
}

variable "region_short" {
}

variable "ip_cidr_range" {
}

variable "hub_vpc_url" {}

variable "ncc_hub_id" {}

variable "fgt_firmware_family" {
  type = string
  default = "fortigate-70-byol"
  description = "FGT image firmware family"
}

variable "cnt" {
  type = number
  default = 2
  description = "How many FortiGates you want to deploy: 2 or 3"
}

variable "machine_type" {
  type = string
  default = "e2-standard-2"
  description = "Machine type to use for FortiGates"
}

variable "service_account" {
  type = string
  default = ""
  description = "Service account to be linked to FGT instances. If not provided default compute engine account will be used"
}

variable "healthcheck_port" {
  type = number
  default = 8008
  description = "ELB health checks will be using this port, FGTs will be configured to respond on the same"
}

variable "fgt_asn" {
  type = number
  default = 65001
  description = "ASN to be assigned to FGTs and configured in BGP peerings"
}

variable "ncc_asn" {
  type = number
  default = 65000
  description = "ASN to be assigned to cloud router and configured in BGP peerings"
}

variable "admin_acl" {
  type = set(string)
  default = ["0.0.0.0/0"]
  description = "ACL to assign to administrative interface of FGT"
}

variable "license_files" {
  type = list(string)
  default = ["1.lic","2.lic","3.lic"]
  description = "List of licence file names in current directory"
}

variable "fmg_ip" {
  type = string
  default = null
  description = "IP address of FortiManager used to bootstrap connection from FGTs"
}

variable "fmg_serial" {
  type = string
  default = null
  description = "Serial of FortiManager used to bootstrap connection from FGTs"
}


variable "project" {}
