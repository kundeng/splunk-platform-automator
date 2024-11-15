output "hosts" {
  description = "Map of created Splunk hosts"
  value = {
    for env_name, env in module.provider_impl :
    env_name => env.hosts
  }
}
