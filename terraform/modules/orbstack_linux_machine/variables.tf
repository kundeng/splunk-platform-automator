variable "machines" {
  description = "A map of machines to create"
  type = map(object({
    name         = string
    distro       = string
    architecture = string
  }))
}

variable "username" {
  description = "The username to create as a passwordless sudo user"
  type        = string
}

variable "orbstack_cli_path" {
  description = "Path to the OrbStack CLI binary"
  type        = string
  default     = "orb"
}
