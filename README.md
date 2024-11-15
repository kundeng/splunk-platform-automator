# Splunk Infrastructure Automation with Terraform and Ansible

## Overview

This project provides infrastructure automation for Splunk deployments using Terraform and Ansible. It uses OrbStack as the primary virtualization provider, offering a modern, efficient alternative to traditional virtualization on ARM-based macOS systems.

## Features

- Infrastructure provisioning with Terraform
- OrbStack-based virtualization (optimized for ARM macOS)
- Ansible-based configuration management
- Dynamic inventory generation
- Unified configuration through `splunk_config.yml`
- Future support planned for AWS

## Prerequisites

- macOS with Apple Silicon (M1/M2)
- Python 3.x
- Terraform
- Ansible
- Task (for workflow automation)
- OrbStack installed and configured

## Quick Start

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/splunk-platform-automator.git
   cd splunk-platform-automator
   ```

2. Initialize the environment:
   ```bash
   task init
   ```

3. Copy and customize a configuration:
   ```bash
   cp examples/idx_3shc_uf_orbstack.yml config/splunk_config.yml
   # Edit config/splunk_config.yml for your needs
   ```

4. Deploy:
   ```bash
   task example:deploy -- idx_3shc_uf_orbstack.yml
   ```

## Configuration

### splunk_config.yml

The `splunk_config.yml` file is the single source of truth for your deployment. It defines:

- OrbStack virtualization settings
- Splunk instance configurations
- Clustering setup
- Network configurations
- Security settings

Example configurations can be found in the `examples/` directory.

### Provider Settings

#### OrbStack (Current)
```yaml
virtualization: orbstack
orbstack:
  default_image: almalinux:9
  ansible_user: root
```

#### AWS (Future)
Support for AWS deployment will be added in future releases.

## Development

### Directory Structure
```
.
├── ansible/          # Ansible configuration and playbooks
├── config/          # Configuration files
├── examples/        # Example configurations
├── terraform/       # Terraform modules and environments
└── tests/           # Test suite
```

### Workflow

Common tasks are automated using Taskfile:

- `task init` - Initialize development environment
- `task plan` - Plan infrastructure changes
- `task apply` - Apply infrastructure changes
- `task ansible:deploy` - Deploy Splunk configuration
- `task test` - Run tests
- `task lint` - Run linters

## Current Status

- [x] Project structure setup
- [x] OrbStack provider implementation
- [x] Basic Splunk deployment automation
- [x] Dynamic inventory generation
- [ ] Advanced clustering configurations
- [ ] AWS provider implementation (future)

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the Apache 2.0 License - see the LICENSE file for details.
