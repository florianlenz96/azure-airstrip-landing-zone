variable "stage" {
  type = string
}
variable "root_id" {
  type = string
}
variable "subscription_id" {
  type = string
}
variable "name" {
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
variable "other_spoke_prefixes" {
  type    = set(string)
  default = []
}
variable "hub" {
  type = object({
    id                         = string
    name                       = string
    resource_group_name        = string
    subscription_id            = string
    firewall_private_ip        = string
    private_dns_zones          = map(string)
    log_analytics_workspace_id = string
  })
}
variable "subnets" {
  type = map(object({
    address_prefixes  = list(string)
    private_endpoints = optional(bool, false)
    delegation = optional(object({
      name    = string
      actions = list(string)
    }))
    rules = optional(map(object({
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = optional(string, "*")
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    })), {})
  }))
}
