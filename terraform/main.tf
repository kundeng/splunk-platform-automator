terraform {
  required_version = ">= 0.13"
}

# Load and parse the Ansible inventory
locals {
  inventory = yamldecode(file("${path.module}/../inventory_output.yml"))
  
  # Extract all splunk_env_* groups and their hosts
  splunk_environments = {
    for group_name, group in local.inventory.all.children :
    group_name => group.hosts
    if can(regex("^splunk_env_", group_name))
  }

  # Provider module selection based on var.provider_type
  provider_module = {
    orbstack = "./modules/orbstack"
    aws      = "./modules/aws"
  }
}

# Create environment-specific configurations
module "splunk_environments" {
  for_each = local.splunk_environments
  
  # Use provider module based on configuration
  source = lookup(local.provider_module, var.provider_type)
  
  hosts       = each.value
  environment = trimprefix(each.key, "splunk_env_")

  # Pass provider-specific configuration
  providers = var.provider_config[var.provider_type]
}

output "environments" {
  description = "Created Splunk environments"
  value = {
    for env_name, env in module.splunk_environments :
    env_name => env.hosts
  }
}
