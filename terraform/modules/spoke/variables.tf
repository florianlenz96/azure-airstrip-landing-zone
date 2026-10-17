variable "stage" {
  type = string
  validation {
    condition     = var.stage == "regional_airfield"
    error_message = "Spoke networking requires regional_airfield."
  }
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
  validation {
    condition     = alltrue([for key in ["owner", "cost-center", "env"] : try(length(trimspace(var.tags[key])) > 0, false)])
    error_message = "Network tags must include nonempty owner, cost-center and env."
  }
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
  validation {
    condition     = length(var.subnets) > 0 && alltrue([for subnet in values(var.subnets) : !(subnet.private_endpoints && subnet.delegation != null)])
    error_message = "Provide subnets; private-endpoint subnets cannot be delegated."
  }
  validation {
    condition = alltrue(flatten([
      for subnet in values(var.subnets) : [
        for name, rule in subnet.rules :
        rule.priority >= 200 && rule.priority <= 4000 &&
        contains(["Inbound", "Outbound"], rule.direction) &&
        contains(["Allow", "Deny"], rule.access) &&
        contains(["Tcp", "Udp", "Icmp", "*"], rule.protocol) &&
        !contains(["allow-hub-dns", "deny-unspecified-inbound", "deny-unspecified-private-outbound"], name)
      ]
      ])) && alltrue([
      for subnet in values(var.subnets) :
      length(subnet.rules) == length(distinct([for rule in values(subnet.rules) : "${rule.direction}/${rule.priority}"]))
    ])
    error_message = "Use unique NSG priorities per direction (200-4000), valid direction/access/protocol and non-reserved names."
  }
}
