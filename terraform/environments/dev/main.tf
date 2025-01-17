terraform {
  required_version = ">= 0.13"
}

# Create Splunk platform using the platform module
module "platform" {
  source = "../../modules/platform"

  environment_name = terraform.workspace
  inventory_file   = "${path.module}/../../../config/inventory_output.yml"
  provider_config  = var.provider_config
}

# Output platform hosts
output "hosts" {
  description = "Created hosts and their configurations"
  value = module.platform
}
