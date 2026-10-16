variable "root_id" {
  description = "ID prefix of the management groups, used for resource names."
  type        = string
}

variable "root_management_group_id" {
  description = "ID of the root management group (diagnostic policies are assigned there)."
  type        = string
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
