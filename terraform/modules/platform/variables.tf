variable "environment_name" {
  description = "Name of the environment (e.g., dev, prod)"
  type        = string
}

variable "inventory_file" {
  description = "Path to the Ansible inventory file"
  type        = string
}

variable "provider_config" {
  description = "Provider configuration including type and settings"
  type = object({
    provider_type     = string
    settings = map(any)
  })
  
  validation {
    condition     = contains(["orbstack", "aws"], var.provider_config.provider_type)
    error_message = "Provider type must be one of: orbstack, aws"
  }
}
