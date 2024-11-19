output "ansible_inventory" {
  description = "Host inventory for Ansible"
  value = join("\n", flatten([
    ["# Generated by Terraform - Host configurations"],
    [for env_name, env in module.orbstack : 
      [for name, machine in env.machines : "${name} ip_addr=${machine.ip} public_dns_name=${name}.orb.local"]
    ],
    [""]  # Add final newline
  ]))
}
