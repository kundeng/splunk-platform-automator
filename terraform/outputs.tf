# Output all container information in a format suitable for Ansible inventory
output "ansible_inventory" {
  description = "Container information formatted for Ansible inventory"
  value = {
    for hostname, container in orbstack_container.splunk_hosts : hostname => {
      ansible_host  = "${hostname}@orb"
      ansible_user  = var.ansible_user
      orbstack_image = container.image
      labels       = container.labels
      environment  = container.environment
    }
  }
}

# Output group information based on container labels
output "ansible_groups" {
  description = "Group assignments for Ansible inventory"
  value = {
    for role in distinct(values(orbstack_container.splunk_hosts)[*].labels.role) : "role_${role}" => [
      for name, container in orbstack_container.splunk_hosts : name
      if container.labels.role == role && role != "none"
    ]
  }
}
