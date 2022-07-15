variable "prefix" {
  type = string
  default = "fgtncc"
  description = "Prefix to be added to all created resources"
}

variable "project" {
  type = string
  description = "Google project id"
}

variable "region" {
  type = string
  default = "europe-west3"
  description = "Region to deploy to"
}

variable "zones" {
  type = list(string)
  default = ["","",""]
  description = "List of zones to deploy to. If not provided zones will be pulled automatically from region"
}

variable "cnt" {
  type = number
  default = 2
  description = "How many FortiGates you want to deploy: 2 or 3"
}

variable "service_account" {
  type = string
  default = ""
  description = "Service account to be linked to FGT instances. If not provided default compute engine account will be used"
}

variable "license_files" {
  type = list(string)
  default = ["1.lic","2.lic","3.lic"]
  description = "List of licence file names in current directory"
}

variable "machine_type" {
  type = string
  default = "e2-standard-2"
  description = "Machine type to use for FortiGates"
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

variable "hub_cidr_range" {
  type = string
  default = "172.20.0.0/24"
  description = "CIDR to assign to regional subnet in NCC Hub VPC"
}

variable "fgt_firmware_family" {
  type = string
  default = "fortigate-70-byol"
  description = "FGT image firmware family"
}

variable "wrkld_vpcs" {
  type = list(object({
   name = string
   project = string
  }))
  default = []
  description = "List of VPCs to be peered with NCC Hub VPC"
}
