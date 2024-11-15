module "splunk_platform" {
  source = "../../modules/platform"

  environment_name = "dev"
  inventory_file   = "${path.module}/../../../inventory_output.yml"
  provider_config  = var.provider_config
}

output "splunk_hosts" {
  description = "Created Splunk hosts"
  value       = module.splunk_platform.hosts
}
