# Splunk Infrastructure Automation with Terraform and Ansible

## Overview

This project aims to migrate the existing Splunk deployment automation solution from Vagrant to Terraform. It will maintain the current Ansible-based configuration management while replacing Vagrant with Terraform for infrastructure provisioning.

## Goals

1. Replace Vagrant with Terraform for all infrastructure provisioning.
2. Support multiple providers (OrbStack, VirtualBox, AWS, LXC) through Terraform.
3. Preserve and extend the current Ansible dynamic inventory system.
4. Maintain and enhance the current `splunk_config.yml` file format.

## Approach

1. Use Terraform as the primary tool for infrastructure provisioning across all supported providers.
2. Adapt the existing Ansible dynamic inventory to work with Terraform-provisioned resources.
3. Extend the `splunk_config.yml` format to include provider-specific configurations for Terraform.
4. Implement provider modules in Terraform, starting with OrbStack and gradually adding others.

## Current Status

- Existing Vagrant and Ansible-based system is functional.
- Initial Terraform configuration for OrbStack integration has been created.

## Todo List [P: Pending, D: Done, C: Canceled, F: Deferred for refinement]

1. [P] Implement OrbStack provisioning in Terraform.
2. [P] Adapt existing Ansible dynamic inventory to work with Terraform output.
3. [P] Extend `splunk_config.yml` to include Terraform-specific configurations for all providers.
4. [P] Ensure Ansible can connect to Terraform-provisioned VMs across all providers.
5. [P] Implement VirtualBox provider in Terraform.
6. [P] Implement AWS provider in Terraform.
7. [P] Implement LXC provider in Terraform.
8. [P] Test full workflow from `splunk_config.yml` to configured Splunk instances on all providers.
9. [P] Document new Terraform-based workflow and configuration options.
10. [P] Create migration guide for users moving from Vagrant to Terraform-based setup.
11. [P] Remove Vagrant-specific code and configurations.

## Next Steps

1. Focus on implementing OrbStack provisioning in Terraform.
2. Adapt the existing Ansible dynamic inventory to work with Terraform-provisioned resources.
3. Extend `splunk_config.yml` to include Terraform-specific configurations for OrbStack.
