variable "root_id" {
  description = "ID prefix for all management groups. Must be unique in the tenant."
  type        = string
  default     = "airstrip"
}

variable "root_display_name" {
  description = "Display name of the root management group below the tenant root."
  type        = string
  default     = "Airstrip"
}

variable "workloads" {
  description = "Workload management groups per landing zone (key = short name, value = display name)."
  type = object({
    corp   = optional(map(string), {})
    online = optional(map(string), {})
  })
  default = {}

  validation {
    condition = alltrue([
      for k in concat(keys(var.workloads.corp), keys(var.workloads.online)) :
      can(regex("^[a-z0-9-]+$", k))
    ])
    error_message = "Workload keys must contain only lowercase letters, digits and hyphens."
  }
}

variable "subscriptions" {
  description = "Existing subscription IDs per management group. Key = management group (management, connectivity, identity, corp, online, sandbox, decommissioned or <corp|online>-<workload>)."
  type        = map(list(string))
  default     = {}

  validation {
    condition     = length(flatten(values(var.subscriptions))) == length(distinct(flatten(values(var.subscriptions))))
    error_message = "Each subscription may be assigned to only one management group."
  }
}

variable "allowed_locations" {
  description = "Azure regions where resources and resource groups may be created."
  type        = list(string)
}

variable "logging_location" {
  description = "Region of the logging resource group, workspace and policy identities."
  type        = string
  default     = "westeurope"
}

variable "log_retention_days" {
  description = "Retention of the central Log Analytics workspace."
  type        = number
  default     = 30
}

variable "defender_plans" {
  description = "Paid Defender for Cloud plans to enable on the management subscription."
  type = object({
    servers   = optional(bool, false)
    storage   = optional(bool, false)
    key_vault = optional(bool, false)
    arm       = optional(bool, false)
  })
  default = {}
}

variable "stage" {
  description = "Runway stage. Existing full-hierarchy deployments must select regional_airfield when upgrading."
  type        = string
  default     = "grass_strip"

  validation {
    condition     = contains(["grass_strip", "regional_airfield"], var.stage)
    error_message = "stage must be grass_strip or regional_airfield."
  }
}
