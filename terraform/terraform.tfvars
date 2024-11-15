# Default provider configuration
provider_type = "orbstack"

# Provider-specific configurations
provider_config = {
  orbstack = {
    default_image = "almalinux:9"
  }
  aws = {
    region = "us-west-2"
    default_instance_type = "t3.micro"
    default_ami = "ami-0c3b25f791b4808c9"
  }
}
