# OrbStack Linux Machines Terraform Module

This Terraform module provisions Linux machines on OrbStack, creates a passwordless sudo user, and updates the `/etc/hosts` file on each machine with the IP addresses of all other machines.

## Features

1. Create Linux machines with specified distributions and architectures
2. Add a passwordless sudo user during machine creation
3. Update `/etc/hosts` on each machine with all created machines' IPs

## Requirements

- OrbStack CLI installed and available in PATH
- Terraform >= 0.13
- Linux/macOS environment

## Usage

```hcl
module "orbstack_linux_machines" {
  source = "./modules/orbstack_linux_machine"

  username = "orbuser"

  machines = {
    machine1 = {
      name         = "web-server"
      distro       = "ubuntu"
      architecture = "amd64"
    },
    machine2 = {
      name         = "db-server"
      distro       = "debian"
      architecture = "amd64"
    }
  }
}

output "machine_ips" {
  value = module.orbstack_linux_machines.machine_ips
}

output "hosts_entries" {
  value = module.orbstack_linux_machines.hosts_entries
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| machines | A map of machines to create | `map(object)` | n/a | yes |
| username | The username for the passwordless sudo user | `string` | n/a | yes |
| orbstack_cli_path | Path to the OrbStack CLI binary | `string` | `"orb"` | no |

### Machine Configuration

Each machine in the `machines` map requires the following attributes:

- `name`: The name of the machine (must be unique)
- `distro`: The Linux distribution to use (e.g., "ubuntu", "debian")
- `architecture`: The CPU architecture (e.g., "amd64", "arm64")

## Outputs

| Name | Description |
|------|-------------|
| machine_ips | Map of machine names to their IP addresses |
| hosts_entries | Content of the generated hosts file entries |

## Notes

- The module creates a temporary directory (`.tmp`) to store IP addresses and hosts file entries
- Each machine will have its `/etc/hosts` file updated with the IPs of all other machines
- The module uses the OrbStack CLI to create and manage machines
