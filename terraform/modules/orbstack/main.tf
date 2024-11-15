locals {
  # Convert inventory hosts to provider-specific format
  hosts = {
    for hostname, host_config in var.hosts :
    hostname => {
      image = coalesce(host_config.orbstack_image, var.settings.default_image)
      user  = host_config.ansible_user
      # Add other OrbStack-specific configurations
    }
  }
}

# Create OrbStack VMs using shell commands
resource "null_resource" "vms" {
  for_each = local.hosts

  triggers = {
    host_config = jsonencode(each.value)
    environment = var.environment
  }

  provisioner "local-exec" {
    command = <<-EOT
      orb create ${each.key} \
        --image ${each.value.image} \
        --user ${each.value.user}
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "orb rm -f ${each.key}"
  }
}
