locals {
  # Load and parse the Ansible inventory
  inventory = try(yamldecode(file(var.inventory_file)), {})

  # Extract all splunk_env_* groups and their hosts
  splunk_envs = {
    for group_name, group in try(local.inventory.all.children, {}) :
    replace(group_name, "splunk_env_", "") => group.hosts
    if can(regex("^splunk_env_", group_name))
  }

  # Normalize host configurations for provider
  normalized_envs = {
    for env_name, hosts in local.splunk_envs : env_name => {
      for hostname, host in hosts : hostname => {
        orbstack_image = try(host.orbstack_image, null)
      }
    }
  }
}

# Create resources using orbstack provider
module "orbstack" {
  source = "../orbstack"
  for_each = local.normalized_envs
  
  environment = each.key
  hosts = each.value
  default_image = try(var.provider_config.settings.default_image, "almalinux:9")
  ansible_user = try(var.provider_config.settings.ansible_user, "root")
}

# Create resources using AWS provider
module "aws" {
  source = "../aws"
  count  = var.provider_config.provider_type == "aws" ? 1 : 0
  
  environment = var.environment_name
  hosts = {}
}

# Output created hosts
output "hosts" {
  description = "Created hosts and their configurations"
  value = {
    for env_name, env in module.orbstack : env_name => {
      hosts_entries = env.hosts_entries
      machines = env.machines
    }
  }
}
