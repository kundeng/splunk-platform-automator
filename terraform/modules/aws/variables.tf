variable "hosts" {
  description = "Map of host configurations from the Ansible inventory"
  type = map(object({
    ansible_host    = string
    ansible_user    = string
    orbstack_image  = string
  }))
}

variable "environment" {
  description = "Name of the Splunk environment"
  type        = string
}

variable "ami_map" {
  description = "Mapping of OrbStack images to AWS AMIs"
  type        = map(string)
  default     = {
    "almalinux:9" = "ami-0c3b25f791b4808c9"  # Example AMI ID
  }
}

variable "default_ami" {
  description = "Default AMI to use if no mapping exists"
  type        = string
  default     = "ami-0c3b25f791b4808c9"  # Example AMI ID
}
