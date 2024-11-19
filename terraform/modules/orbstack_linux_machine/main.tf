# Create a Linux machine and set up a passwordless sudo user
resource "null_resource" "orbstack_machine" {
  for_each = var.machines

  # Create the machine and set up the user
  provisioner "local-exec" {
    command = "orb create --arch ${each.value.architecture == "aarch64" ? "arm64" : each.value.architecture} -u ${var.username} ${each.value.distro} ${each.value.name}"
    interpreter = ["/bin/bash", "-c"]
    on_failure  = continue
    when = create
  }

  triggers = {
    name         = each.value.name
    distro       = each.value.distro
    architecture = each.value.architecture
    username     = var.username
  }
}

# Use external data source to collect IPs
data "external" "machine_ips" {
  for_each = var.machines
  depends_on = [null_resource.orbstack_machine]

  program = ["bash", "-c", <<-EOT
    IP=$(orb run -m "${each.value.name}" hostname -I | cut -d' ' -f1)
    echo "{\"ip\": \"$${IP:-}\"}"
  EOT
  ]
}

locals {
  # Create a map of machine name to IP
  ip_map = {
    for name, machine in var.machines : 
    name => data.external.machine_ips[name].result.ip
    if data.external.machine_ips[name].result.ip != ""
  }

  # Create hosts entries string
  hosts_entries = join("\n", [
    for name, ip in local.ip_map : 
    "${ip} ${name}"
  ])
}

# Update hosts files on all machines
resource "null_resource" "update_hosts" {
  for_each = var.machines
  depends_on = [data.external.machine_ips]

  provisioner "local-exec" {
    command = <<-EOT
      if [ -n "${local.hosts_entries}" ]; then
        # First remove existing terraform block if present
        orb -m "${each.value.name}" sudo sed -i.bak '/# BEGIN TERRAFORM MANAGED BLOCK/,/# END TERRAFORM MANAGED BLOCK/d' /etc/hosts
        
        # Add new protected segment
        echo "# BEGIN TERRAFORM MANAGED BLOCK
${local.hosts_entries}
# END TERRAFORM MANAGED BLOCK" | orb -m "${each.value.name}" sudo tee -a /etc/hosts
      else
        echo "No hosts entries to add"
      fi
    EOT
    interpreter = ["/bin/bash", "-c"]
  }

  triggers = {
    hosts_entries = local.hosts_entries
    machine_name = each.value.name
  }
}
