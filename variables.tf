variable "prefix" {
  type = string
  default = "fgtncc"
}

variable "project" {
  type = string
}

variable "region" {
  type = string
  default = "europe-west3"
}

variable "zones" {
  type = list(string)
  default = ["","",""]
}

variable "cnt" {
  type = number
  default = 2
}

variable "service_account" {
  type = string
  default = ""
}

variable "license_files" {
  type = list(string)
  default = ["1.lic","2.lic","3.lic"]
}

variable "machine_type" {
  type = string
  default = "e2-standard-2"
}

variable "healthcheck_port" {
  type = number
  default = 8008
}

variable "fgt_asn" {
  type = number
  default = 65001
}

variable "ncc_asn" {
  type = number
  default = 65000
}

variable "admin_acl" {
  type = set(string)
  default = ["0.0.0.0/0"]
}

variable "fmg_ip" {
  type = string
  default = null
}

variable "fmg_serial" {
  type = string
  default = null
}
