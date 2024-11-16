# Splunk Platform Automator Configuration Flow

This document details how configurations are processed and applied in the Splunk Platform Automator, using concrete examples.

## Overview

The configuration process follows this high-level flow:
1. Entry point through `deploy_site.yml`
2. Role setup through `setup_splunk_roles.yml`
3. Configuration application through `setup_splunk_conf.yml`

## Detailed Flow

### 1. Deployment Server Role (deployment_server/tasks/main.yml)

The deployment server role has two main responsibilities:

1. **Local Instance Configuration**:
   ```yaml
   - name: apply baseconfig app org_all_forwarder_outputs
     include_role:
       name: baseconfig_app
     vars:
       app_name: 'org_all_forwarder_outputs'
       app_path: '{{splunk_home}}/etc/apps'
   ```
   This installs and configures apps for the deployment server itself.

2. **Deployment Apps Configuration**:
   ```yaml
   - name: apply baseconfig app org_all_forwarder_outputs
     include_role:
       name: baseconfig_app
     vars:
       app_name: 'org_all_forwarder_outputs'
       app_path: '{{ splunk_home }}/etc/deployment-apps'
       # Dynamic configuration from inventory
       splunk_output_list: "{{ hostvars[groups['output_'+splunk_env_name+'_'+output_name][0]]['splunk_output_list'] }}"
   ```
   This prepares apps to be deployed to other Splunk instances.

### 2. Configuration Modification Process

Taking org_all_forwarder_outputs as an example:

1. **Initial Template** (org_all_forwarder_outputs/local/outputs.conf):
   ```ini
   [tcpout]
   defaultGroup = primary_indexers 

   [tcpout:primary_indexers]
   server = server_one:9997, server_two:9997
   ```

2. **Dynamic Configuration** (baseconfig_app/tasks/org_all_forwarder_outputs.yml):
   ```yaml
   # 1. Modify defaultGroup based on environment
   - name: "setting defaultGroup value"
     ini_file:
       section: tcpout
       option: defaultGroup
       value: "{{ splunk_outputs_tcpout_list|map('regex_replace','^(.*)$','\\1_indexers')|join(',') }}"

   # 2. Configure indexer discovery
   - name: "setting indexerDiscovery"
     ini_file:
       section: "tcpout:{{ item.idxc_name+'_indexers' }}"
       option: indexerDiscovery
       value: "{{ item.idxc_name+'_indexers' }}"

   # 3. Set up SSL if enabled
   - name: "setting ssl configs"
     ini_file:
       section: "tcpout:all_indexers"
       option: "{{ item.key }}"
       value: "{{ item.value }}"
     with_dict: "{{ splunk_ssl.outputs.config }}"
   ```

Each modification:
- Updates the configuration file
- Triggers a Splunk restart if needed
- Contributes to the final `splunk_conf` structure

### 3. Configuration Tracking

Configurations are tracked in multiple ways:

1. **Through splunk_conf Variable**:
   ```yaml
   splunk_conf:
     outputs.conf:
       tcpout:
         defaultGroup: "idx1_indexers,idx2_indexers"
         indexerDiscovery: "clustered_indexers"
       "tcpout:idx1_indexers":
         server: "idx1.splunk.example:9997"
   ```

2. **Through File Modifications**:
   - Each `ini_file` task modifies the actual configuration files
   - Changes are tracked in the app's local/ directory
   - Modifications trigger Splunk restarts via notify

3. **Through Serverclass Configuration**:
   ```yaml
   - name: save serverclass file
     synchronize:
       src: "{{ splunk_install_dir }}/splunk/etc/system/local/serverclass.conf"
       dest: "../{{splunk_save_baseconfig_apps_dir|default('apps')}}/"
   ```
   This tracks which configurations should be deployed to which clients.

### 4. Configuration Sources and Flow

1. **Default Values**:
   - Come from base configuration apps in `Software/Configurations - Base/`
   - Provide template configurations

2. **Dynamic Values**:
   - From inventory variables (hostvars, group_vars)
   - From role-specific variables
   - Example:
     ```yaml
     splunk_outputs_tcpout_list: ["idx1", "idx2"]
     splunk_ssl:
       outputs:
         enable: true
         config:
           sslVerifyServerCert: true
     ```

3. **Final Configuration**:
   - Base templates + Dynamic values
   - Applied through `splunk_conf` role
   - Tracked in serverclass.conf for deployment

### 5. Security and Validation

1. **File Permissions**:
   ```yaml
   - name: "set secure permissions"
     ini_file:
       mode: 0600  # Restrictive permissions for sensitive configs
       owner: "{{splunk_user}}"
       group: "{{splunk_group}}"
   ```

2. **SSL Configuration**:
   ```yaml
   - name: "install certs"
     include_role:
       name: baseconfig_app
       tasks_from: splunk_ssl_outputs_certs
     when: splunk_ssl.outputs.enable == true
   ```

### 6. Configuration Precedence

1. Base app defaults
2. Environment-specific values (from inventory)
3. Role-specific modifications
4. SSL and security settings
5. Final `splunk_conf` application

## Key Files and Their Roles

1. **Role Configuration**:
   - `deployment_server/tasks/main.yml`: Orchestrates app installation and configuration
   - `baseconfig_app/tasks/org_*.yml`: App-specific configuration logic
   - `splunk_conf/tasks/add_splunk_conf.yml`: Final configuration application

2. **Templates and Defaults**:
   - `Software/Configurations - Base/*/local/*.conf`: Base configuration templates
   - `group_vars/`: Environment-specific defaults
   - `host_vars/`: Host-specific overrides

3. **Tracking and Deployment**:
   - `serverclass.conf`: Deployment mappings
   - Local app directories: Modified configurations
   - `splunk_conf` variable: Accumulated changes

## Configuration Sources

Base configuration apps structure:
```
./Software/Configurations - Base/
├── org_all_forwarder_outputs/
│   ├── local/
│   │   ├── outputs.conf
│   │   └── app.conf
│   └── metadata/
│       └── local.meta
├── org_all_search_base/
└── org_ds_secure_server/
```

## Variable Flow

1. **Initial Variables**:
   - Set by inventory plugin
   - Defined in group_vars/host_vars
   ```yaml
   # group_vars/all/splunk_conf.yml
   splunk_conf:
     outputs.conf:
       tcpout:
         defaultGroup: primary_indexers
   ```

2. **Configuration Variables**:
   - Built by baseconfig_app role
   ```yaml
   # After baseconfig_app processing
   splunk_conf:
     outputs.conf:
       tcpout:
         defaultGroup: value
         indexerDiscovery: value
     web.conf:
       settings:
         enableSplunkWebSSL: true
   ```

3. **Final Application**:
   - Transformed by splunk_conf role
   ```yaml
   # Final splunk_conf_settings_list
   splunk_conf_settings_list:
   - section: tcpout
     key: defaultGroup
     value: primary_indexers
   ```

## Deployment Server App Management

1. **App Deployment** (deployment_server/tasks/save_serverclass.yml):
```yaml
- name: save serverclass file
  synchronize:
    src: "{{ splunk_install_dir }}/splunk/etc/system/local/serverclass.conf"
    dest: "../{{splunk_save_baseconfig_apps_dir|default('apps')}}/..."
```

## Key Files and Their Roles

1. **Playbooks**:
   - `ansible/deploy_site.yml`: Entry point, orchestrates entire deployment
   - `ansible/setup_splunk_roles.yml`: Sets up each Splunk role
   - `ansible/setup_splunk_conf.yml`: Applies final configurations

2. **Roles**:
   - `ansible/roles/deployment_server/`: Manages app deployment
   - `ansible/roles/baseconfig_app/`: Handles base app installation
   - `ansible/roles/splunk_conf/`: Applies final configurations

3. **Configuration Sources**:
   - `Software/Configurations - Base/`: Contains base apps
   - `group_vars/`: Group-specific variables
   - `host_vars/`: Host-specific variables

## Configuration Precedence

1. Default configurations from base apps
2. Role-specific modifications
3. Host/group variable overrides
4. Final splunk_conf application

## Security Considerations

1. File Permissions:
```yaml
- name: set file permissions
  file:
    path: "{{ app_path }}/{{ app_dest_name }}"
    mode: 0644
    owner: "{{splunk_user}}"
    group: "{{splunk_group}}"
```

2. SSL Configuration:
```ini
# SSL Settings in outputs.conf
sslCertPath = $SPLUNK_HOME/etc/auth/server.pem
sslRootCAPath = $SPLUNK_HOME/etc/auth/ca.pem
sslVerifyServerCert = true
```

## Example: Configuring a Deployment Server

Let's follow exactly what happens when setting up a deployment server role, from start to finish.

### 1. Entry Point: deploy_site.yml

When you run `ansible-playbook deploy_site.yml`, this triggers:

```yaml
# deploy_site.yml
- name: setup splunk roles
  tags: [splunk, splunk_roles]
  import_playbook: setup_splunk_roles.yml
```

### 2. Role Assignment (setup_splunk_roles.yml)

The deployment server role is assigned to hosts in the role_deployment_server group:

```yaml
# setup_splunk_roles.yml
- name: setup deployment server role
  hosts: role_deployment_server
  become: yes
  become_user: root
  roles:
    - deployment_server
```

### 3. Base Configuration Apps

Let's look at one specific app: org_all_forwarder_outputs

1. **Initial State** (Software/Configurations - Base/org_all_forwarder_outputs/local/outputs.conf):
```ini
[tcpout]
defaultGroup = primary_indexers 

[tcpout:primary_indexers]
server = server_one:9997, server_two:9997
```

2. **Deployment Server Processing** (deployment_server/tasks/main.yml):
```yaml
# First, install for local instance
- name: apply baseconfig app org_all_forwarder_outputs
  include_role:
    name: baseconfig_app
  vars:
    app_name: 'org_all_forwarder_outputs'
    app_path: '{{splunk_home}}/etc/apps'

# Then, prepare for deployment to other instances
- name: apply baseconfig app org_all_forwarder_outputs
  include_role:
    name: baseconfig_app
  vars:
    app_name: 'org_all_forwarder_outputs'
    app_path: '{{ splunk_home }}/etc/deployment-apps'
    # Get dynamic values from inventory
    splunk_output_list: "{{ hostvars[groups['output_'+splunk_env_name+'_'+output_name][0]]['splunk_output_list'] }}"
```

### 4. Configuration Modification Flow

Let's track how the configuration changes through each step:

1. **Base App Installation** (baseconfig_app/tasks/install_app.yml):
```yaml
# 1. Find the app
- name: find path to baseconfig app
  find:
    path: "{{ splunk_baseconfig }}/"
    pattern: "org_all_forwarder_outputs"
  register: baseapp_dir

# 2. Copy initial files
- name: copy local files
  copy:
    src: "{{ baseapp_dir.files.0.path }}/local/*"
    dest: "{{ splunk_home }}/etc/apps/org_all_forwarder_outputs/local/"
```

2. **Dynamic Configuration** (baseconfig_app/tasks/org_all_forwarder_outputs.yml):
```yaml
# 3. Update defaultGroup based on environment
- name: "setting defaultGroup value"
  ini_file:
    path: ".../outputs.conf"
    section: tcpout
    option: defaultGroup
    value: "{{ splunk_outputs_tcpout_list|map('regex_replace','^(.*)$','\\1_indexers')|join(',') }}"

# 4. Configure indexer discovery
- name: "setting indexerDiscovery"
  ini_file:
    path: ".../outputs.conf"
    section: "tcpout:{{ item.idxc_name+'_indexers' }}"
    option: indexerDiscovery
    value: "{{ item.idxc_name+'_indexers' }}"
```

### 5. Configuration State Changes

Let's see how outputs.conf evolves:

1. **Initial State**:
```ini
[tcpout]
defaultGroup = primary_indexers 

[tcpout:primary_indexers]
server = server_one:9997, server_two:9997
```

2. **After defaultGroup Update** (assuming environment has idx1, idx2):
```ini
[tcpout]
defaultGroup = idx1_indexers,idx2_indexers 

[tcpout:primary_indexers]
server = server_one:9997, server_two:9997
```

3. **After Indexer Discovery**:
```ini
[tcpout]
defaultGroup = idx1_indexers,idx2_indexers 

[tcpout:idx1_indexers]
server = idx1-1:9997,idx1-2:9997
indexerDiscovery = idx1_indexers

[tcpout:idx2_indexers]
server = idx2-1:9997,idx2-2:9997
indexerDiscovery = idx2_indexers

[indexer_discovery:idx1_indexers]
pass4SymmKey = your_secret_key
manager_uri = https://cm1.splunk.example:8089

[indexer_discovery:idx2_indexers]
pass4SymmKey = your_secret_key
manager_uri = https://cm2.splunk.example:8089
```

### 6. Variable Tracking

Throughout this process, configurations are tracked in `splunk_conf`:

```yaml
# Initial state
splunk_conf:
  outputs.conf:
    tcpout:
      defaultGroup: primary_indexers
    tcpout:primary_indexers:
      server: server_one:9997, server_two:9997

# After modifications
splunk_conf:
  outputs.conf:
    tcpout:
      defaultGroup: idx1_indexers,idx2_indexers
    tcpout:idx1_indexers:
      server: idx1-1:9997,idx1-2:9997
      indexerDiscovery: idx1_indexers
    tcpout:idx2_indexers:
      server: idx2-1:9997,idx2-2:9997
      indexerDiscovery: idx2_indexers
    indexer_discovery:idx1_indexers:
      pass4SymmKey: your_secret_key
      manager_uri: https://cm1.splunk.example:8089
```

### 7. Final Steps

1. **Serverclass Configuration**:
```ini
# serverclass.conf
[serverClass:forwarder_outputs]
whitelist.0 = *
[serverClass:forwarder_outputs:app:org_all_forwarder_outputs]
repository = $SPLUNK_HOME/etc/deployment-apps/org_all_forwarder_outputs
```

2. **Deployment Tracking**:
```yaml
- name: save serverclass file
  synchronize:
    src: "{{ splunk_install_dir }}/splunk/etc/system/local/serverclass.conf"
    dest: "../apps/{{inventory_hostname}}/..."
```

### 8. Result

After this process:
1. The deployment server has its local outputs.conf configured
2. A deployable version of org_all_forwarder_outputs is prepared in deployment-apps
3. Serverclass.conf is configured to deploy this app to appropriate clients
4. All configurations are tracked in both files and variables

This example shows how a single app's configuration flows through the system, gets modified based on environment variables, and is prepared for deployment to other Splunk instances.
