variable "landingzones_management_group_id" {
  type = string
}

variable "corp_management_group_id" {
  type = string
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "allowed_envs" {
  type    = list(string)
  default = ["dev", "test", "prod"]
}

variable "stage" {
  description = "Public endpoints are denied only in regional_airfield."
  type        = string
  default     = "grass_strip"

  validation {
    condition     = contains(["grass_strip", "regional_airfield"], var.stage)
    error_message = "stage must be grass_strip or regional_airfield."
  }
}

variable "exemptions" {
  description = "Explicit Corp exceptions. Scope must be a Corp subscription, resource group, or resource."
  type = map(object({
    scope         = string
    description   = string
    category      = optional(string, "Waiver")
    expires_on    = string
    reference_ids = optional(list(string), [])
  }))
  default = {}

  validation {
    condition = alltrue([
      for e in values(var.exemptions) :
      contains(["Waiver", "Mitigated"], e.category) &&
      length(trimspace(e.description)) > 0 && can(timecmp(e.expires_on, e.expires_on)) &&
      can(regex("(?i)^/subscriptions/[a-f0-9-]{36}(/resourceGroups/[^/]+(/providers/[^/]+(/[^/]+/[^/]+)+)?)?$", e.scope))
    ])
    error_message = "Exemptions require a subscription/resource-group/resource scope, justification, Waiver/Mitigated category and RFC3339 expiry."
  }
}
