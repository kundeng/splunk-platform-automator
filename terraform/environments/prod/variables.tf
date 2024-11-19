variable "provider_type" {
  description = "Type of provider to use (orbstack, aws)"
  type        = string
  default     = "aws"
}

variable "provider_config" {
  description = "Provider configuration including type and settings"
  type = object({
    type = string
    settings = map(any)
  })
  default = {
    type = "aws"
    settings = {
      region = "us-west-2"
      default_instance_type = "t3.medium"
      default_ami = "ami-0735c191cf914754d" # Amazon Linux 2023
    }
  }
  
  validation {
    condition = var.provider_config.type == "aws"
    error_message = "Prod environment only supports AWS provider"
  }
}
