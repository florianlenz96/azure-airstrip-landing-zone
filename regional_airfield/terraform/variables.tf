variable "stage" {
  type    = string
  default = "regional_airfield"
  validation {
    condition     = var.stage == "regional_airfield"
    error_message = "Use grass_strip/terraform for Grass strip."
  }
}

variable "root_id" {
  type    = string
  default = "airstrip"
}

variable "root_display_name" {
  type    = string
  default = "Airstrip"
}

variable "workloads" {
  type = object({
    corp   = optional(map(string), {})
    online = optional(map(string), {})
  })
  default = {}
}

variable "subscriptions" {
  type    = map(list(string))
  default = {}
}

variable "allowed_locations" {
  type = list(string)
}

variable "logging_location" {
  type    = string
  default = "westeurope"
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "defender_plans" {
  type = object({
    servers   = optional(bool, false)
    storage   = optional(bool, false)
    key_vault = optional(bool, false)
    arm       = optional(bool, false)
  })
  default = {}
}

variable "allowed_envs" {
  type    = list(string)
  default = ["dev", "test", "prod"]
}

variable "exemptions" {
  type = map(object({
    scope         = string
    description   = string
    category      = optional(string, "Waiver")
    expires_on    = string
    reference_ids = optional(list(string), [])
  }))
  default = {}
}
