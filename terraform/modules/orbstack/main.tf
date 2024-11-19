locals {
  # Convert inventory hosts to provider-specific format
  machines = {
    for hostname, host_config in var.hosts :
    hostname => {
      name         = try(host_config.machine_name, hostname)
      distro       = split(":", try(host_config.orbstack_image, var.default_image))[0]
      architecture = try(host_config.architecture, "amd64")
    }
  }
}

module "orbstack_machines" {
  source = "../orbstack_linux_machine"

  machines = {
    for hostname, machine in local.machines :
    hostname => {
      name         = machine.name
      distro       = machine.distro
      architecture = machine.architecture
    }
  }
  username = var.ansible_user

  # Optional: Configure OrbStack CLI path if needed
  orbstack_cli_path = "orb"
}

# Export the machine information
output "machine_details" {
  description = "Created OrbStack machines and their details"
  value = module.orbstack_machines.machine_ips
}
