variable "provider_config" {
  description = "Provider configuration including type and settings"
  type = object({
    provider_type = string
    settings = map(any)
  })
  default = {
    provider_type = "orbstack"
    settings = {
      default_image = "almalinux:9"
      ansible_user = "ansible"
    }
  }
  
  validation {
    condition = var.provider_config.provider_type == "orbstack"
    error_message = "Dev environment only supports orbstack provider"
  }
}
