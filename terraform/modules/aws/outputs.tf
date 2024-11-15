output "hosts" {
  description = "Created host configurations"
  value = {
    for hostname, instance in aws_instance.splunk_hosts :
    hostname => {
      public_ip     = instance.public_ip
      instance_id   = instance.id
      instance_type = instance.instance_type
    }
  }
}
