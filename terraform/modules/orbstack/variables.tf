variable "environment" {
  description = "Name of the environment (e.g., dev, prod)"
  type        = string
}

variable "hosts" {
  description = "Map of host configurations from the Ansible inventory"
  type = map(object({
    ansible_host    = string
    ansible_user    = string
    orbstack_image  = string
  }))
}

variable "settings" {
  description = "OrbStack-specific settings"
  type        = map(any)
  
  validation {
    condition     = can(lookup(var.settings, "default_image", null))
    error_message = "OrbStack settings must include 'default_image'"
  }
}
