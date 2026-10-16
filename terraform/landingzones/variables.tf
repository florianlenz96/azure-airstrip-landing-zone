variable "root_id" {
  description = "ID prefix of the management groups, same value as in platform/."
  type        = string
  default     = "airstrip"
}

variable "location" {
  description = "Region of the managed identities used by the Modify policies."
  type        = string
  default     = "westeurope"
}

variable "allowed_envs" {
  description = "Allowed values for the env tag on resource groups in the landing zones."
  type        = list(string)
  default     = ["dev", "test", "prod"]
}
