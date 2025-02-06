# Technical Documentation

This document provides technical details about the infrastructure implementation, OrbStack integration, and inventory management in the Splunk Platform Automator.

# Part 1: Infrastructure Implementation

## 1. Ansible Inventory System

### Base Inventory Processing
The system processes Ansible inventory in multiple stages:

1. Initial YAML Configuration:
```yaml
# Example configuration (idx_sh_uf_orbstack.yml)
plugin: splunk-platform-automator
orbstack:
  image: alma:9        # Base image for all machines
  ansible_user: root   # Default user for Ansible connections

splunk_hosts:
  - name: idx1         # Machine name (used for DNS)
    roles:            # Splunk roles determine machine purpose
      - indexer       # This machine will be a Splunk indexer
```

Key Points:
- `plugin`: Identifies this as a Splunk Platform Automator config
- `orbstack`: Provider-specific settings that apply to all machines
- `splunk_hosts`: List of machines with their roles and configurations

2. Core Processing:
```python
def _populate(self):
    # Process each configuration section (general, custom, os, etc.)
    for section in ['general', 'custom', 'os', 'splunk_dirs', ...]:
        # Initialize empty defaults if section not found
        if section not in self.defaults:
            self.defaults[section] = {}
        # If section exists in config, merge with defaults
        if isinstance(self.configfiles.get(section), dict):
            merged_section = self._merge_dict(self.defaults[section], self.configfiles[section])
```

Understanding the Code:
- Iterates through predefined configuration sections
- Handles missing sections by initializing empty defaults
- Merges user configuration with defaults when present
- Ensures all required settings have values

### OrbStack Integration

The inventory plugin was modified to add OrbStack support:
The inventory plugin was modified to support OrbStack as a new provider:

1. Plugin Registration:
```python
DOCUMENTATION = r'''
    # Added OrbStack support to plugin options
    orbstack:
        description: orbstack settings
        type: dictionary
        required: false
'''

class InventoryModule(BaseInventoryPlugin):
    NAME = 'splunk-platform-automator'
```

2. Provider Detection:
```python
def _set_virtualization(self, splunk_config):
    '''Detect provider from config file'''
    supported_virtualizations = ['virtualbox','aws','orbstack']
    for virtualization in supported_virtualizations:
        if virtualization in splunk_config:
            setattr(self, 'virtualization', virtualization)
```

3. Configuration Processing:
```python
def _process_orbstack_configs(self):
    """
    Process OrbStack-specific variables with precedence:
    1. Host-specific settings
    2. Global OrbStack settings
    3. Default settings
    """
    # Start with defaults
    default_config = self.defaults.get('orbstack', {})
    global_config = self.configfiles.get('orbstack', {})
    
    for hostname in self.inventory.hosts:
        # Layer configurations
        config = default_config.copy()
        config.update(global_config)
        host_config = host_vars.get('orbstack', {})
        config.update(host_config)

        # Set connection variables
        ansible_user = config.get('ansible_user', 'ansible')
        self.inventory.set_variable(hostname, 'ansible_host', 
            f"{ansible_user}@{hostname}@orb")
        self.inventory.set_variable(hostname, 'ansible_ssh_user', 
            f'{ansible_user}@{hostname}')
```

### Configuration Example
```yaml
# Global OrbStack settings
orbstack:
  image: alma:9        # Default image for all machines
  ansible_user: root   # Default user for connections

splunk_hosts:
  - name: idx1
    roles:
      - indexer
    orbstack:          # Host-specific override
      image: rocky:9   # Overrides global image
```

### Why This Design?
1. Configuration Layers:
   - Defaults provide baseline settings
   - Global settings apply to all OrbStack machines
   - Host-specific overrides allow customization

2. Connection Variables:
   - `ansible_host`: `{user}@{hostname}@orb`
     * Required format for OrbStack's SSH implementation
     * Enables direct container access
   - `ansible_ssh_user`: `{user}@{hostname}`
     * Ensures correct user context
     * Maintains Ansible compatibility

3. Integration Points:
   - Inventory plugin detects OrbStack configuration
   - Processes settings before Terraform reads inventory
   - Ensures consistent host configuration

## 2. Infrastructure Implementation
The project uses a clear environment separation:

```
terraform/
├── environments/
│   ├── dev/           # Development environment (OrbStack)
│   │   ├── main.tf    # Environment-specific configuration
│   │   └── variables.tf
│   └── prod/          # Production environment (AWS - planned)
```

Currently focused on the development environment:
```hcl
# dev/main.tf
terraform {
  required_version = ">= 0.13"
}

module "platform" {
  source = "../../modules/platform"
  environment_name = terraform.workspace
  inventory_file   = "${path.module}/../../../config/inventory_output.yml"
  provider_config  = var.provider_config
}
```

## 3. Terraform Module Structure

### Module Hierarchy
The project demonstrates effective use of Terraform modules for code organization and reusability:

```
terraform/
├── modules/
│   ├── platform/          # High-level orchestration
│   │   ├── main.tf       # Coordinates other modules
│   │   └── variables.tf  # Common variables
│   ├── orbstack/         # OrbStack-specific logic
│   │   ├── main.tf       # Provider configuration
│   │   └── variables.tf  # OrbStack variables
│   └── orbstack_linux_machine/  # Low-level machine management
│       ├── main.tf       # Machine creation/configuration
│       └── variables.tf  # Machine-specific variables
```

### Module Organization and Flow

1. Platform Module (Top Level):
   ```hcl
   # platform/main.tf
   module "provider" {
     source = "../orbstack"  # Use OrbStack provider
     hosts  = local.hosts    # Pass processed inventory
   }
   ```
   - Acts as the main orchestrator
   - Reads and processes inventory
   - Delegates to appropriate provider module
   - Manages environment-specific settings

2. Provider Module (Middle Layer):
   ```hcl
   # orbstack/main.tf
   locals {
     # Transform inventory hosts into provider format
     machines = {
       for hostname, config in var.hosts :
       hostname => {
         name = hostname
         distro = try(config.orbstack_image, var.default_image)
       }
     }
   }
   ```
   - Implements provider-specific logic
   - Transforms generic config to provider format
   - Handles provider-specific resources
   - Manages network and DNS configuration

3. Machine Module (Bottom Layer):
   ```hcl
   # orbstack_linux_machine/main.tf
   resource "null_resource" "machine" {
     for_each = var.machines
     
     provisioner "local-exec" {
       # Create machine using OrbStack CLI
       command = "orb create -u ${var.username} ${each.value.distro} ${each.value.name}"
     }
   }
   ```
   - Handles individual machine lifecycle
   - Implements provider-specific commands
   - Manages machine-level configuration
   - Ensures proper cleanup on destroy

### Key Module Features
1. Module Composition:
   ```hcl
   module "orbstack_machines" {
     source = "../orbstack_linux_machine"
     machines = local.machines
     username = var.ansible_user
   }
   ```

2. Local Variables:
   ```hcl
   locals {
     machines = {
       for hostname, host_config in var.hosts :
       hostname => {
         name         = try(host_config.machine_name, hostname)
         distro       = split(":", try(host_config.orbstack_image, var.default_image))[0]
         architecture = try(host_config.architecture, "amd64")
       }
     }
   }
   ```

3. Resource Management:
   ```hcl
   resource "null_resource" "orbstack_machine" {
     for_each = var.machines
     triggers = {
       name         = each.value.name
       distro       = each.value.distro
       architecture = each.value.architecture
     }
   }
   ```

## 4. Infrastructure Evolution

### From Vagrant to Terraform
The project has evolved from using Vagrant to Terraform for infrastructure management, bringing several improvements:
- Better state management
- More flexible provider support
- Cleaner separation of concerns

## 5. Configuration Flow

### YAML Configuration Structure
```yaml
# Example configuration (idx_sh_uf_orbstack.yml)
plugin: splunk-platform-automator

orbstack:
  image: alma:9
  ansible_user: root

splunk_hosts:
  - name: idx1
    roles:
      - indexer
  - name: sh1
    roles:
      - search_head
  - name: uf1
    roles:
      - universal_forwarder
```

The configuration flows through several stages:
1. YAML parsing and validation
2. Environment-specific processing
3. Host configuration generation

# Part 2: OrbStack Integration

## 1. OrbStack Provider Module Deep Dive

### Module Structure
```hcl
# orbstack/main.tf
module "orbstack_machines" {
  source = "../orbstack_linux_machine"
  machines = local.machines
  username = var.ansible_user
}

# orbstack_linux_machine/main.tf
resource "null_resource" "orbstack_machine" {
  for_each = var.machines
  
  # Machine Creation
  provisioner "local-exec" {
    command = "orb create --arch ${each.value.architecture == "aarch64" ? "arm64" : each.value.architecture} -u ${var.username} ${each.value.distro} ${each.value.name}"
    when = create
  }
  
  # Machine Cleanup
  provisioner "local-exec" {
    command = "orbctl delete ${self.triggers.name}"
    when = destroy
  }
}
```

### How It Works
1. Machine Creation:
   - Uses `null_resource` since OrbStack lacks a native provider
   - Executes OrbStack CLI commands via local-exec provisioner
   - Handles architecture mapping (aarch64 → arm64)

2. State Management:
   - Uses triggers to track machine configuration
   - Enables proper update and destroy operations
   - Maintains idempotency through resource tracking

3. Network Configuration:
   ```hcl
   data "external" "machine_ips" {
     program = ["bash", "-c", "IP=$(orb run -m \"${each.value.name}\" hostname -I | cut -d' ' -f1)"]
   }
   ```
   - Collects IP addresses after machine creation
   - Uses external data source for dynamic information
   - Updates host files across all machines

4. Integration with Ansible:
   - Generates inventory in required format
   - Provides necessary connection information
   - Ensures proper DNS resolution

## 2. Network and DNS Management

### IP Address Collection
The system collects IP addresses through Terraform's external data source:
```hcl
data "external" "machine_ips" {
  program = ["bash", "-c", <<-EOT
    IP=$(orb run -m "${each.value.name}" hostname -I | cut -d' ' -f1)
    echo "{\"ip\": \"$${IP:-}\"}"
  EOT
  ]
}
```

### Host File Management
Terraform manages the host file entries:
```hcl
resource "null_resource" "update_hosts" {
  provisioner "local-exec" {
    command = <<-EOT
      # Add new protected segment
      echo "# BEGIN TERRAFORM MANAGED BLOCK
${local.hosts_entries}
# END TERRAFORM MANAGED BLOCK" | orb -m "${each.value.name}" sudo tee -a /etc/hosts
    EOT
  }
}
```

### Why Both IP and DNS?
1. IP Addresses:
   - Required for direct network communication
   - Used by Ansible for SSH connections
   - Needed for Splunk's network protocols

2. DNS Names:
   - Required for Splunk clustering
   - Used for service discovery
   - Provides stable naming across restarts

## 3. Configuration Processing

### Variable Precedence
1. Default Settings:
   - Defined in `defaults/` directory
   - Provide baseline configuration

2. Global OrbStack Settings:
   - Defined in main config file
   - Apply to all OrbStack hosts

3. Host-specific Settings:
   - Override global settings
   - Allow per-host customization


# Implementation Notes

1. Development Focus:
   - Currently using only the dev environment
   - OrbStack optimized for ARM-based macOS
   - Future AWS support planned

2. Key Files:
   - `terraform/environments/dev/main.tf`: Environment configuration
   - `terraform/modules/orbstack/main.tf`: OrbStack implementation
   - `ansible/plugins/inventory/splunk-platform-automator.py`: Inventory management

3. Important Considerations:
   - Always use fully qualified paths in Terraform
   - Maintain host file consistency across all nodes
   - Consider DNS resolution requirements for Splunk services
