variable "environment" {
  description = "Environment name"
  type        = string
}

variable "hosts" {
  description = "Map of host configurations from inventory"
  type        = map(any)
}

variable "default_image" {
  description = "Default container image to use for Splunk hosts"
  type        = string
  default     = "almalinux:9"
}

variable "ansible_user" {
  description = "Default user for Ansible to connect with"
  type        = string
  default     = "root"
}
