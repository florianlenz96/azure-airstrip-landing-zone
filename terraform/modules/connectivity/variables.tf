variable "stage" {
  type = string
  validation {
    condition     = var.stage == "regional_airfield"
    error_message = "The connectivity stack is only available in regional_airfield."
  }
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
  validation {
    condition     = alltrue([for key in ["owner", "cost-center", "env"] : try(length(trimspace(var.tags[key])) > 0, false)])
    error_message = "Network tags must include nonempty owner, cost-center and env."
  }
}

variable "address_space" {
  type = list(string)
}

variable "firewall_subnet" {
  type = string
  validation {
    condition     = can(cidrnetmask(var.firewall_subnet)) && try(tonumber(split("/", var.firewall_subnet)[1]) <= 26, false)
    error_message = "AzureFirewallSubnet must be a valid IPv4 CIDR of /26 or larger."
  }
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
  validation {
    condition = alltrue([
      for rule in values(var.network_rules) :
      length(rule.source_addresses) > 0 && length(rule.destination_addresses) > 0 &&
      length(rule.destination_ports) > 0 && length(rule.protocols) > 0 &&
      alltrue([for source in rule.source_addresses : !contains(["*", "0.0.0.0/0", "Internet"], source)]) &&
      alltrue([for destination in rule.destination_addresses : !contains(["*", "0.0.0.0/0", "Internet"], destination)]) &&
      !contains(rule.destination_ports, "*") &&
      alltrue([for protocol in rule.protocols : contains(["TCP", "UDP", "ICMP"], protocol)])
    ])
    error_message = "Firewall network rules need explicit sources, destinations, ports and TCP/UDP/ICMP protocols; broad Internet rules are not allowed."
  }
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
  validation {
    condition = alltrue([
      for rule in values(var.application_rules) :
      length(rule.source_addresses) > 0 && length(rule.destination_fqdns) > 0 && length(rule.protocols) > 0 &&
      alltrue([for source in rule.source_addresses : !contains(["*", "0.0.0.0/0", "Internet"], source)]) &&
      alltrue([for fqdn in rule.destination_fqdns : length(trimspace(fqdn)) > 0 && length(regexall("\\*", fqdn)) == 0]) &&
      alltrue([for protocol in rule.protocols : contains(["Http", "Https"], protocol.type) && protocol.port >= 1 && protocol.port <= 65535])
    ])
    error_message = "Firewall application rules need explicit sources/FQDNs and valid Http/Https protocols; wildcard access is not allowed."
  }
}
