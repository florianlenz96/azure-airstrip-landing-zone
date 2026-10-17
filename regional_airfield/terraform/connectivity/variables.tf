variable "stage" {
  type = string
}
variable "root_id" {
  type = string
}
variable "subscription_id" {
  type = string
}
variable "location" {
  type = string
}
variable "tags" {
  type = map(string)
}
variable "address_space" {
  type = list(string)
}
variable "firewall_subnet" {
  type = string
}
variable "private_dns_zones" {
  type = set(string)
}
variable "log_analytics_workspace_id" {
  type = string
}
variable "network_rules" {
  type = map(object({
    protocols             = list(string)
    source_addresses      = list(string)
    destination_addresses = list(string)
    destination_ports     = list(string)
  }))
  default = {}
}
variable "application_rules" {
  type = map(object({
    source_addresses  = list(string)
    destination_fqdns = list(string)
    protocols = list(object({
      type = string
      port = number
    }))
  }))
  default = {}
}
