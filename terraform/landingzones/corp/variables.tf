variable "root_id" {
  description = "ID prefix of the management groups, same value as in platform/."
  type        = string
  default     = "airstrip"
}

variable "public_endpoints_effect" {
  description = "Effect of the no-public-endpoints policies in the corp management group."
  type        = string
  default     = "Audit"

  validation {
    condition     = contains(["Audit", "Deny", "Disabled"], var.public_endpoints_effect)
    error_message = "Must be Audit, Deny or Disabled."
  }
}
