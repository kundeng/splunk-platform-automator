output "machines" {
  description = "Information about all created machines"
  value       = module.orbstack_machines.machine_info
}

output "hosts_entries" {
  description = "Entries added to /etc/hosts"
  value       = module.orbstack_machines.hosts_entries
}
