# Required, user input
variable "vpc" {
  type = string
}

# Required, user input
variable "subnet" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "c5.2xlarge"
}

variable "key_name" {
  type    = string
  default = null
}

variable "sg_ports" {
  type = map(string)
  default = {
    22 : "SSH Access",
    4200 : "LogStream Distributed Management Port",
    9000 : "LogStream Leader UI Access"
  }
}