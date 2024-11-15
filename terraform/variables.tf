variable "default_image" {
  description = "Default container image to use for Splunk hosts"
  type        = string
  default     = "rocky:9"
}

variable "ansible_user" {
  description = "Default user for Ansible to connect with"
  type        = string
  default     = "root"
}

variable "splunk_home" {
  description = "Path to Splunk installation directory"
  type        = string
  default     = "/opt/splunk"
}

variable "splunk_user" {
  description = "User to run Splunk as"
  type        = string
  default     = "splunk"
}

variable "provider_type" {
  description = "Type of provider to use (orbstack, aws)"
  type        = string
  default     = "orbstack"
}

variable "provider_config" {
  description = "Provider-specific configuration"
  type = map(any)
  default = {
    orbstack = {
      default_image = "almalinux:9"
    }
    aws = {
      region = "us-west-2"
      default_instance_type = "t3.micro"
      default_ami = "ami-0c3b25f791b4808c9"
    }
  }
}
