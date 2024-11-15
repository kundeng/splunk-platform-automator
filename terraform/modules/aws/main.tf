terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

locals {
  # Convert inventory hosts to AWS-specific format
  instances = {
    for hostname, host_config in var.hosts :
    hostname => {
      ami           = lookup(var.ami_map, host_config.orbstack_image, var.default_ami)
      instance_type = "t3.micro"  # This should be configurable
      user_data     = templatefile("${path.module}/templates/user_data.sh.tpl", {
        ansible_user = host_config.ansible_user
      })
      tags = {
        Name        = hostname
        Environment = var.environment
      }
    }
  }
}

# Placeholder for AWS implementation
resource "aws_instance" "splunk_hosts" {
  for_each = local.instances

  ami           = each.value.ami
  instance_type = each.value.instance_type
  user_data     = each.value.user_data
  tags          = each.value.tags

  # Add other AWS-specific configurations
}
