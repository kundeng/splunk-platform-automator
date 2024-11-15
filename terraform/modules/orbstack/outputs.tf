output "hosts" {
  description = "Created host configurations"
  value = {
    for hostname, vm in null_resource.vms :
    hostname => jsondecode(vm.triggers.host_config)
  }
}
