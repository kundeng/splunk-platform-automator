# Dynamic Variable Generation in Splunk Platform Automator

This document explains how dynamic variables are generated and used in the Splunk Platform Automator, focusing on the interaction between inventory data and runtime variable generation.

## 1. Overview

The dynamic variable generation system in Splunk Platform Automator serves several key purposes:
1. Transform static inventory data into runtime configurations
2. Handle environment-specific variations
3. Process complex data structures for Splunk configuration
4. Ensure version compatibility

## 1. Ansible Magic Variables

Before diving into the variable generation, it's important to understand the "magic" variables that Ansible provides automatically and are used extensively in dynamic.yml:

1. `hostvars`: A dictionary containing all hosts and their variables
   ```yaml
   # Access variables of a specific host
   hostvars['dpl']['ansible_host']  # Gets ansible_host of 'dpl'
   ```

2. `groups`: A dictionary of all groups and their member hosts
   ```yaml
   # Example structure
   groups:
     all: ['dpl', 'idx', 'sh1', 'sh2']
     role_deployment_server: ['dpl']
     splunk_env_splk: ['dpl', 'idx', 'sh1', 'sh2']
   ```

3. `group_names`: List of groups the current host is a member of
   ```yaml
   # For host 'dpl', might show:
   group_names: ['role_deployment_server', 'splunk_env_splk']
   ```

These magic variables are automatically populated by Ansible and are essential for the dynamic variable generation in group_vars/all/dynamic.yml.

## 2. Variable Sources

### A. Environment Name Source

The `splunk_env_name` variable originates from the defaults:

1. Default value in defaults/splunk_defaults.yml:
   ```yaml
   splunk_defaults:
     splunk_env_name: splk  # Default environment name
   ```

2. The inventory plugin:
   - Loads this default value
   - Can be overridden by splunk_config.yml settings
   - Makes it available as a group variable for 'all'

3. This is why in dynamic.yml we can use:
   ```yaml
   splunk_env_name: "{{ splunk_env_name }}"  # References the default value
   ```

4. The plugin then uses this value to create environment-specific groups:
   ```yaml
   # Creates group like 'splunk_env_splk'
   default_splunk_env = "splunk_env_" + self.groups['all']['splunk_env_name']
   ```

### B. Inventory Structure
```yaml
# Example from actual inventory output
all:
  children:
    # Environment group (splk environment)
    splunk_env_splk:
      hosts:
        dpl:  # Deployment server
          ansible_host: ansible@dpl@orb
          splunk_env_name: splk
          splunk_output_list:    # Defines forwarding targets
            indexer:
              - idx             # Forward to standalone indexer
        idx:  # Indexer
          ansible_host: ansible@idx@orb
          splunk_env_name: splk
    
    # Role-based groups
    role_deployment_server:
      hosts:
        dpl: {}    # Empty dict means no additional vars
    role_indexer:
      hosts:
        idx: {}
```

Let's break this down:
1. `all.children`: Root of all groups
   - Groups are categorized by purpose (environment, role, etc.)
   - Each host can belong to multiple groups

2. `splunk_env_splk`: Environment group
   - Groups hosts by environment (e.g., splk, prod, dev)
   - Contains environment-specific variables
   - Example: `splunk_env_name: splk`

3. `role_*` groups: Role-based classification
   - `role_deployment_server`: Deployment servers
   - `role_indexer`: Indexer nodes
   - Empty dicts (`{}`) mean no additional variables

### B. Host Variables
```yaml
# Detailed host variables for dpl (deployment server)
dpl:
  # Connection details
  ansible_host: ansible@dpl@orb
  ansible_ssh_user: ansible@dpl
  ansible_user: ansible

  # Environment settings
  splunk_env_name: splk
  
  # Output configuration
  splunk_outputs: all           # Enable all outputs
  splunk_output_list:           # Define output targets
    indexer:
      - idx                     # Forward to idx host

  # SSL Configuration (referenced by *id003)
  splunk_ssl: &id003           # Anchor for YAML reference
    inputs:
      config:
        rootCA: $SPLUNK_HOME/etc/auth/cacert.pem
        serverCert: $SPLUNK_HOME/etc/auth/server.pem
      enable: false
    outputs:
      config:
        sslCertPath: $SPLUNK_HOME/etc/auth/server.pem
        sslRootCAPath: $SPLUNK_HOME/etc/auth/cacert.pem
      enable: false
```

## 3. Dynamic Variable Generation

### A. Environment Processing
```yaml
# From dynamic.yml - Process environment name
splunk_env_name: "{{ splunk_env_name }}"

# Get all hosts in current environment
splunk_env_hosts: >-
  {%- set res = [] -%}
  {%- for host in groups['all'] -%}
    {%- if host in groups['splunk_env_'+splunk_env_name] -%}
      {%- set ignored = res.extend([host]) -%}
    {%- endif -%}
  {%- endfor -%}
  {{ res }}
```

This code uses a special syntax called Jinja templating to generate a list of hosts based on the environment name. Here's how it works:

1. `splunk_env_name` is a variable that comes from the host's own variables (e.g., 'splk').
2. `groups['splunk_env_'+splunk_env_name]` is a way of looking up a group in the `groups` dictionary that is named like 'splunk_env_splk'. The `+` is called string concatenation, and it's used to build the group name by adding the value of `splunk_env_name` to the string 'splunk_env_'.
3. `for host in groups['all']` is a loop that goes through all the hosts in the `groups` dictionary.
4. `if host in groups['splunk_env_'+splunk_env_name]` is a way of checking if the current host is a member of the group we looked up in step 2. If it is, then...
5. `set ignored = res.extend([host])` is a way of adding the host to a list called `res`. The `extend` method adds all the elements of the list to the end of `res`. The `set ignored =` part is just a way of throwing away the return value of the `extend` method.
6. Finally, `{{ res }}` is a way of outputting the final list of hosts as a YAML array. The `{{ }}` is called a Jinja expression, and it's used to insert the value of a variable into a string.



### B. Role Resolution
```yaml
# Generate list of roles for current host
splunk_roles: >-
  {%- set res = [] -%}
  {%- for role_name in groups|map('regex_search','role_.*')|select('string')|list -%}
    {%- if inventory_hostname in groups[role_name] -%}
      {%- set ignored = res.extend([role_name|replace("role_","")]) -%}
    {%- endif -%}
  {%- endfor -%}
  {{ res|join(', ') }}
```

Step by step:
1. `groups|map('regex_search','role_.*')`
   - Takes all group names
   - Finds ones starting with 'role_'
   - For our inventory: ['role_deployment_server', 'role_indexer', ...]

2. `|select('string')|list`
   - Removes any non-matching (None) results
   - Converts to list

3. `if inventory_hostname in groups[role_name]`
   - Checks if current host is in each role group
   - Example: for 'dpl' host, checks membership in each role_* group

4. `role_name|replace("role_","")`
   - Removes 'role_' prefix
   - Example: 'role_deployment_server' → 'deployment_server'

Example output:
```yaml
# For dpl host:
splunk_roles: "deployment_server, monitoring_console"

# For idx host:
splunk_roles: "indexer"
```

### C. Output Configuration Generation
```yaml
# Generate indexer lists from inventory
splunk_outputs_idx_list: "{{ 
  splunk_output_list['indexer']|default([]) |
  intersect(groups['splunk_env_'+splunk_env_name]) 
}}"
```

Example transformation:
1. Input from inventory:
   ```yaml
   splunk_output_list:
     indexer:
       - idx
   ```

2. Process steps:
   ```yaml
   # Step 1: Get indexer list
   splunk_output_list['indexer'] = ['idx']
   
   # Step 2: Get environment hosts
   groups['splunk_env_splk'] = ['dpl', 'idx', 'sh1', 'sh2', 'sh3', 'uf']
   
   # Step 3: Find intersection
   ['idx'] ∩ ['dpl', 'idx', 'sh1', 'sh2', 'sh3', 'uf'] = ['idx']
   ```

3. Final output:
   ```yaml
   splunk_outputs_idx_list: ['idx']
   ```

This ensures that:
- Only valid indexers are included
- Indexers must exist in the current environment
- Non-existent hosts are filtered out

## 4. Variable Processing Patterns

### A. List Operations
1. **Filtering and Mapping**:
   ```yaml
   # Filter and transform list elements
   result: "{{ input_list|map('regex_replace','^(.*)$','\\1_suffix') }}"
   ```

2. **Set Operations**:
   ```yaml
   # Find common elements
   intersection: "{{ list1|intersect(list2) }}"
   
   # Combine unique elements
   union: "{{ list1|union(list2) }}"
   
   # Remove elements
   difference: "{{ list1|difference(list2) }}"
   ```

### B. Dictionary Operations
1. **Key Access**:
   ```yaml
   # Access nested dictionary values
   value: "{{ dict['key1']['key2'] }}"
   ```

2. **Default Values**:
   ```yaml
   # Provide default if key missing
   value: "{{ dict['key']|default([]) }}"
   ```

### C. String Operations
1. **Pattern Matching**:
   ```yaml
   # Find items matching pattern
   matches: "{{ items|map('regex_search','pattern')|select('string') }}"
   ```

2. **String Transformation**:
   ```yaml
   # Replace text in strings
   transformed: "{{ text|replace('old','new') }}"
   ```

## 5. Version-Aware Processing

### A. Version Comparison
```yaml
# Adjust configuration based on Splunk version
splunk_cluster_manager_mode: "{%- if 
  splunk_installed_version is version_compare('9.0', '>=') 
-%}manager{%- else -%}master{%- endif -%}"
```

### B. Feature Flags
```yaml
# Enable/disable features based on version
splunk_feature_flag: "{%- if 
  splunk_installed_version is version_compare('8.0', '>=') 
-%}new_feature{%- else -%}old_feature{%- endif -%}"
```

## 6. Best Practices

1. **Variable Naming**:
   - Use descriptive prefixes (`splunk_`, `idxc_`, etc.)
   - Indicate variable type in name (`_list`, `_dict`, etc.)
   - Keep names consistent across related variables

2. **Template Structure**:
   - Use `>-` for multi-line templates
   - Strip whitespace with `{%-` and `-%}`
   - Initialize result variables at start

3. **Error Handling**:
   - Provide defaults with `|default()`
   - Check for existence before access
   - Use conditional blocks for optional features

4. **Performance**:
   - Minimize nested loops
   - Use set operations instead of loops where possible
   - Cache frequently accessed values
