# OrbStack SSH User Handling Issue

## Issue Description
OrbStack's SSH implementation doesn't handle the `-o User=` option as expected:
1. When connecting to `hostname@orb`, specifying `-o User=username` doesn't work
2. The connection falls back to using the current OS user instead
3. This makes it impossible to use standard SSH/Ansible user configuration

## Impact on Ansible
This is a critical issue because we cannot modify:
1. Ansible's core SSH handling (hardcoded `-o User` behavior)
2. Existing Ansible roles from Galaxy or other sources
3. Third-party collections that assume standard SSH behavior

For example, these common patterns all break:
```yaml
# Standard inventory - connects as current OS user because of -o User=ansible:
ansible_host: hostname@orb
ansible_user: ansible

# Common role pattern - fails because role assumes ansible_user works:
- name: Create app directory
  file:
    path: "/home/{{ ansible_user }}/app"
    owner: "{{ ansible_user }}"
    mode: '0755'
    state: directory

# Third-party collection - breaks because it uses ansible_user for SSH and paths:
- name: Deploy application
  include_role:
    name: company.product.deploy
  vars:
    app_user: "{{ ansible_user }}"
```

## Steps to Reproduce
```bash
# These all connect as current OS user (kundeng) instead of 'ansible':
ssh -o User=ansible hostname@orb
ssh -o User=ansible ansible@hostname@orb

# Only this exact format works to connect as 'ansible':
ssh -o User=ansible@hostname ansible@hostname@orb
```

## Workaround Issues
The suggested workaround in docs doesn't help:
```yaml
# This breaks Ansible tasks:
root@ubuntu@orb ansible_user=root@ubuntu
```
- Ansible treats "root@ubuntu" as literal username
- Creates wrong paths like "/home/root@ubuntu"
- User/group tasks fail
- Still doesn't solve the `-o User` issue
- Cannot modify third-party roles to handle this

## Expected Behavior
- Standard SSH `-o User=username` should work
- Ansible should be able to control the connection user normally
- User specification should align with standard SSH behavior
- Existing roles and collections should work without modification

## Environment
- OS: macOS
- Tool: Ansible 2.17.5 (core SSH behavior cannot be modified)
- Python: 3.10
- Target OS: AlmaLinux 9
- Affected: All existing Ansible roles and collections

## Recommendations
1. Make `-o User=username` work as expected with `hostname@orb`
2. If not possible, document clearly:
   - That `-o User` works differently with OrbStack
   - The exact format required: `-o User=user@host` with `user@host@orb`
   - That this breaks standard Ansible user management
   - That this breaks existing roles and collections
   - That there is no workaround that preserves compatibility
