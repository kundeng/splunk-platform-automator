output "machine_ips" {
  description = "IP addresses of the created machines"
  value       = local.ip_map
}

output "hosts_entries" {
  description = "Entries added to /etc/hosts"
  value       = local.hosts_entries
}

output "machine_info" {
  description = "Information about created machines"
  value       = { for name, machine in var.machines : name => {
    name = machine.name
    distro = machine.distro
    architecture = machine.architecture
    ip = lookup(local.ip_map, name, "")
  }}
}
