variable "provider_config" {
  description = "Provider configuration including type and settings"
  type = object({
    type = string
    settings = map(any)
  })
  default = {
    type = "orbstack"
    settings = {
      default_image = "almalinux:9"
    }
  }
}
