locals {
  inventory = yamldecode(file(var.inventory_file))
  
  # Extract all splunk_env_* groups and their hosts
  splunk_environments = {
    for group_name, group in local.inventory.all.children :
    group_name => group.hosts
    if can(regex("^splunk_env_", group_name))
  }

  # Validate provider type
  valid_providers = toset(["orbstack", "aws"])
  provider_type   = var.provider_config.type
  
  validate_provider = (
    contains(local.valid_providers, local.provider_type) ? 
    true : 
    tobool("Invalid provider type: ${local.provider_type}")
  )
}

module "provider_impl" {
  source = "../${var.provider_config.type}"
  
  for_each = local.splunk_environments
  
  environment = var.environment_name
  hosts       = each.value
  settings    = var.provider_config.settings
}
