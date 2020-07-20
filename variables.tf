variable "admin_cidr" {

}

variable "public_key" {
}

variable "enable_fargate_httpbin_firehose" {
  default = true
}

variable "route53_zone_id" { // TODO: make toggle-able?
}
