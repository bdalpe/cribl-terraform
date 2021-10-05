# Required, user input
variable "vpc" {
  type = string
  description = "The VPC where the Cribl LogStream Leader node will be deployed."

  validation {
    condition = can(regex("^vpc-[0-9a-f]+$", var.vpc))
    error_message = "The VPC value must be a valid VPC id, starting with \"vpc-\"."
  }
}

# Required, user input
variable "subnet" {
  type = string
  description = "The VPC Subnet where the Cribl LogStream Leader node will be deployed."

  validation {
    condition = can(regex("^subnet-[0-9a-f]+$", var.subnet))
    error_message = "The subnet value must be a valid subnet id, starting with \"subnet-\"."
  }
}

variable "instance_type" {
  type    = string
  default = "c5.2xlarge"
}

variable "key_name" {
  type    = string
  description = "The SSH key name to be use for the EC2 Instance. If not defined, no SSH key is associated with the instance."
  default = null
}

variable "config_volume_size" {
  type = number
  default = 50
}

variable "config_volume_mountpoint" {
  type = string
  default = "/dev/xvdl"
}

variable "root_block_size" {
  type = number
  default = 8

  validation {
    condition = var.root_block_size >= 8
    error_message = "Root block device size must be greater than 8 GB."
  }
}

variable "encrypt_block_devices" {
  type = bool
  default = true
}

variable "block_device_encryption_kms_key" {
  type = string
  default = null
}

variable "sg_ingress_ports" {
  type = map(object({description = string, protocol = string, cidr_blocks = list(string), ipv6_cidr_blocks = list(string)}))
  default = {
    22 = {
      description = "SSH Access",
      protocol = "TCP",
      cidr_blocks = ["0.0.0.0/0"],
      ipv6_cidr_blocks = ["::/0"]
    },
    4200 = {
      description = "LogStream Distributed Management Port",
      protocol = "TCP",
      cidr_blocks = ["0.0.0.0/0"],
      ipv6_cidr_blocks = ["::/0"]
    },
    9000 = {
      description = "LogStream Leader UI Access",
      protocol = "TCP",
      cidr_blocks = ["0.0.0.0/0"],
      ipv6_cidr_blocks = ["::/0"]
    }
  }
}

variable "sg_egress_ports" {
  type = map(object({description = string, protocol = string, cidr_blocks = list(string), ipv6_cidr_blocks = list(string)}))
  default = {
    0 = {
      description = "Egress Anywhere"
      protocol = -1,
      cidr_blocks = ["0.0.0.0/0"],
      ipv6_cidr_blocks = ["::/0"]
    }
  }
}

variable "user_data" {
  type = string
  default = null
}