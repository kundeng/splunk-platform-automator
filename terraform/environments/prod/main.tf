terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure AWS provider
provider "aws" {
  region = var.provider_config.settings.region
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
