# Splunk Platform Automator

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](#license)

Ever wanted to build a complex Splunk environment for testing, which looks as close as possible to a production deployment? Need to test a Splunk upgrade? See how Splunk indexer- or search head clustering works? Or just need to verify some configuration changes? This is the right place for you! The aim of this framework is to produce a Splunk environment in a fast and convenient way for testing purposes or maybe also for production use. The created Splunk installation and setup follows best practices.

This repository is a modernization of the infrastructure layer of the original [Splunk Platform Automator](https://github.com/splunk/splunk-platform-automator), replacing Vagrant with Terraform while maintaining the robust Ansible-based Splunk configuration and deployment.

## Table of Contents

- [Features](#features)
- [Support](#support)
- [Installation](#installation)
  - [Framework Installation](#framework-installation)
  - [OrbStack Setup](#orbstack-setup)
  - [AWS Support (Future)](#aws-support-future)
- [Architecture and Workflow](#architecture-and-workflow)
- [Environment Users](#environment-users)
- [Development](#development)
- [Known Issues and Limitations](#known-issues-and-limitations)
- [License](#license)

# Features

Core Features:
- Single Source of Truth: All environment configuration defined in one `splunk_config.yml` file
- Modern Infrastructure Layer:
  - Terraform-based infrastructure provisioning
  - OrbStack virtualization optimized for ARM-based macOS
  - Future AWS support planned
- Automated Workflow:
  - Task-based automation for all operations
  - Integrated validation and testing
  - Seamless deployment pipeline
- Configuration Management:
  - Preserves original Ansible-based Splunk configuration
  - Supports all Splunk Enterprise roles
  - Best practice configurations maintained

# Architecture and Workflow

## Overview

The system follows a modern infrastructure-as-code approach with the following components:

```
                                    ┌─────────────────┐
                                    │                 │
                                    │ splunk_config.yml│
                                    │                 │
                                    └────────┬────────┘
                                             │
                                             ▼
┌─────────────────┐               ┌────────────────────┐
│                 │               │                    │
│  Task Workflow  │─────────────▶│  Ansible Inventory  │
│                 │               │                    │
└─────────┬───────┘               └──────────┬─────────┘
          │                                  │
          │                                  ▼
          │                       ┌────────────────────┐
          │                       │                    │
          │                       │     Terraform      │
          │                       │                    │
          │                       └──────────┬─────────┘
          │                                  │
          │                                  ▼
          │                       ┌────────────────────┐
          │                       │                    │
          │                       │  Infrastructure    │
          │                       │                    │
          │                       └──────────┬─────────┘
          │                                  │
          │                                  ▼
          │                       ┌────────────────────┐
          └──────────────────────▶│      Ansible      │
                                 │   Configuration     │
                                 └────────────────────┘
```

## Component Flow

1. **Configuration (`splunk_config.yml`)**
   - Single source of truth for entire environment
   - Defines infrastructure and Splunk configuration
   - Supports multiple provider configurations

2. **Task Workflow**
   - Orchestrates the entire deployment process
   - Manages infrastructure lifecycle
   - Handles configuration validation and deployment

3. **Ansible Inventory Generation**
   - Converts `splunk_config.yml` into dynamic inventory
   - Generates provider-specific host configurations
   - Creates necessary group variables

4. **Terraform Infrastructure**
   - Provisions infrastructure based on inventory
   - Manages provider-specific resources
   - Handles networking and security

5. **Ansible Configuration**
   - Configures Splunk components
   - Applies best practice settings
   - Manages clustering and replication

## Workflow Steps

1. **Initialization**
   ```bash
   task init
   ```
   - Sets up Python environment
   - Installs dependencies
   - Initializes Terraform

2. **Configuration Validation**
   ```bash
   task validate:config
   ```
   - Validates `splunk_config.yml`
   - Checks for required settings
   - Verifies provider configuration

3. **Infrastructure Provisioning**
   ```bash
   task generate:inventory  # Generate Ansible inventory
   task plan               # Plan infrastructure changes
   task apply              # Apply infrastructure changes
   ```
   - Generates dynamic inventory
   - Plans and applies infrastructure changes
   - Sets up networking and security

4. **Splunk Deployment**
   ```bash
   task ansible:deploy
   ```
   - Configures all Splunk components
   - Applies security settings
   - Sets up clustering if configured

## Example Deployment

For a quick start, you can use the example configurations:
```bash
task example:deploy -- idx_3shc_uf_orbstack.yml
```

This will:
1. Load the example configuration
2. Generate inventory
3. Provision infrastructure
4. Deploy and configure Splunk

## Host Management

The system supports two methods for managing host configurations:

### 1. Primary Method: Terraform-managed (Recommended)
- Terraform generates the `inventory/hosts` file during infrastructure provisioning
- Host entries are automatically managed based on your `splunk_config.yml`
- DNS names follow the pattern `hostname.orb.local` for OrbStack
- This is automatically handled when running `task tf:apply`

### 2. Fallback Method: Manual Configuration
For scenarios where Terraform is not managing the infrastructure:
- Create a `config/manual_hosts_mapping.txt` file
- Add your host mappings in the format: `IP_ADDRESS HOSTNAME`
- Enable with `update_hosts_file: true` in your configuration
- Useful for:
  - Existing infrastructure not managed by Terraform
  - Manual host mapping requirements
  - Running Ansible independently of Terraform

Example `manual_hosts_mapping.txt`:
```
192.168.1.10 splunk-idx1
192.168.1.11 splunk-idx2
192.168.1.20 splunk-sh1
```

**Note**: Only use one method at a time to avoid conflicts in host resolution.

# Support

**Note: This framework is not officially supported by Splunk. It is being developed on best effort basis.**

# Installation

## Framework Installation

1. Make sure you have Python 3.6+ installed
2. Install required Python packages:
   ```bash
   python -m pip install jmespath  # required for json_query calls
   python -m pip install lxml      # required for license file checks
   ```
3. Install Ansible (via brew recommended): `brew install ansible`
4. Install Terraform: `brew install terraform`
5. Install Task: `brew install go-task`
6. Create a directory for your deployment
7. Clone this repository
8. Create a `Software` directory and add:
   - [Splunk Enterprise](http://www.splunk.com/en_us/download/splunk-enterprise.html) tgz
   - [Splunk Universal Forwarder](http://www.splunk.com/en_us/download/universal-forwarder.html) tgz
   - [Base Config Apps](https://drive.google.com/open?id=107qWrfsv17j5bLxc21ymTagjtHG0AobF)
   - [Cluster Config Apps](https://drive.google.com/open?id=10aVQXjbgQC99b9InTvncrLFWUrXci3gz)
   - Your Splunk license file (optional, named as `Splunk_Enterprise.lic`)

Your directory structure should look like:
```
./splunk-platform-automator/...
./Software/Configurations - Base/...
./Software/Configurations - Index Replication/...
./Software/splunk-8.1.2-545206cc9f70-Linux-x86_64.tgz
./Software/splunkforwarder-8.1.2-545206cc9f70-Linux-x86_64.tgz
./Software/Splunk_Enterprise.lic
```

## OrbStack Setup

1. Install OrbStack from [orbstack.dev](https://orbstack.dev)
2. Launch OrbStack and complete initial setup
3. Verify OrbStack installation:
   ```bash
   orb version
   ```

## AWS Support (Future)

AWS support is planned for a future release. This will include:
- EC2 instance provisioning
- Security group configuration
- VPC networking setup
- AWS-specific deployment options

# Environment Users

### User splunk
- Primary user for Splunk processes
- Home directory: `/opt/splunk`
- All Splunk processes run as this user
- SSH access available

### Splunk Configuration
- Configuration follows best practices
- Splunk Enterprise in `/opt/splunk`
- Universal Forwarder in `/opt/splunkforwarder`
- Main configuration directories:
  - `/opt/splunk/etc/system/local/`
  - `/opt/splunk/etc/apps/`
  - Cluster-specific configurations in respective directories

### Security Considerations
- Default admin password: Changed on first login
- SSH keys: Generated during deployment
- Firewall rules: Configured per Splunk requirements
- SSL: Can be enabled via configuration

### OrbStack Notes

When using OrbStack as the virtualization platform, there are some important SSH connection behaviors to be aware of:

1. **SSH User Handling**: OrbStack ignores standard SSH user options (`-o User=`) and will always connect using your current OS user, regardless of what's specified in the configuration.
   - Initial connection is always made as your current OS user
   - Root access is handled via Ansible's `become` mechanism
   - This behavior is documented in the example configurations

2. **SSH Connection Format**: OrbStack uses a non-standard format for SSH connections:
   - Use: `user@hostname@orb`
   - Standard SSH options like `-o User=` are ignored

3. **Configuration Impact**: Due to these behaviors:
   - The `ansible_user` setting in orbstack configurations is effectively ignored
   - Root access is handled via `ansible_become: true` in group variables
   - All initial connections use your current OS user

For more details about this behavior and its implications, see [OrbStack SSH Bug Report](docs/orbstack_ssh_bug.md).

# Development

### Directory Structure
```
.
├── ansible/          # Ansible configuration and playbooks
├── config/          # Configuration files
├── defaults/        # Default configuration values
│   ├── aws.yml             # AWS provider defaults
│   ├── general.yml         # General settings
│   ├── orbstack.yml        # OrbStack provider defaults
│   ├── os.yml              # OS-specific settings
│   ├── splunk_apps.yml     # Splunk apps configuration
│   ├── splunk_defaults.yml # Splunk default settings
│   ├── splunk_dirs.yml     # Directory paths
│   ├── splunk_idxclusters.yml  # Indexer cluster settings
│   ├── splunk_shclusters.yml   # Search head cluster settings
│   └── splunk_systemd.yml      # Systemd service settings
├── examples/        # Example configurations
├── terraform/       # Terraform modules and environments
└── tests/          # Test suite
```

### Available Tasks

The project uses [Task](https://taskfile.dev) for workflow automation. Available tasks:

```bash
task: Available tasks for this project:
* ansible:deploy:      Deploy Splunk configuration using Ansible
* ansible:ping:        Test Ansible connectivity to all hosts
* apply:              Apply infrastructure changes
* clean:              Clean up generated files
* default:            Show available tasks
* destroy:            Destroy infrastructure
* example:deploy:     Deploy an example configuration
* format:             Format code
* generate:inventory: Generate Ansible inventory from configuration
* init:               Initialize development environment
* lint:               Run linters
* plan:               Plan infrastructure changes
* test:               Run tests
* validate:config:    Validate splunk_config.yml file
```

### Working with Original Codebase

This project is a modernization of the infrastructure layer of the original [Splunk Platform Automator](https://github.com/splunk/splunk-platform-automator), replacing Vagrant with Terraform and focusing on OrbStack for modern ARM-based systems. The core Ansible automation, which does the majority of the heavy lifting for Splunk deployment and configuration, remains largely unchanged from the original excellent work.

The main changes are:
- Replaced Vagrant with Terraform for infrastructure provisioning
- Added OrbStack support for ARM-based macOS systems
- Updated the configuration structure to support multiple providers
- Enhanced the inventory plugin for new providers

The original codebase can be referenced using these commands:

#### Viewing Original Code
```bash
# View any file from original repo
git show upstream/master:path/to/file

# List files in a directory
git ls-tree -r upstream/master --name-only path/to/dir/

# Compare your changes with original
git diff upstream/master -- path/to/file

# View commit history
git log upstream/master

# Temporarily checkout a file
git checkout upstream/master -- path/to/file
```

### Current Status

- [x] Project structure setup
- [x] OrbStack provider implementation
- [x] Basic Splunk deployment automation
- [x] Dynamic inventory generation
- [ ] Advanced clustering configurations
- [ ] AWS provider implementation (future)

### Development Plan

1. Infrastructure Layer
   - Complete AWS provider implementation
   - Add support for additional cloud providers
   - Enhance provider-specific configurations

2. Configuration Management
   - Maintain compatibility with original Ansible roles
   - Optimize for different provider requirements
   - Add support for new Splunk features

3. Testing
   - Develop comprehensive test suite
   - Add integration tests for each provider
   - Implement automated testing pipeline

4. Documentation
   - Maintain comprehensive setup guides
   - Add provider-specific documentation
   - Create migration guides from Vagrant

5. Future Enhancements
   - Container support
   - Multi-cloud deployments
   - Enhanced monitoring and logging

# Known Issues and Limitations

- AWS support is planned but not yet implemented
- See [original project issues](https://github.com/splunk/splunk-platform-automator/issues) for Splunk-specific limitations

## Supported Ansible Versions

✅ Currently supported:
- Ansible 2.14.x
- Ansible 2.15.x
- Ansible 2.16.x

Check the [Ansible Support Matrix](https://docs.ansible.com/ansible/latest/reference_appendices/release_and_maintenance.html#ansible-core-support-matrix) for current information.

# License

Copyright 2022 Splunk Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
