variable "logstream_version" {
  type = string
  default = "latest"
}

variable "port_mappings" {
  type = list(object({ containerPort = number, hostPort = number }))
  default = [
    {
      protocol = "tcp",
      containerPort = 9000,
      hostPort = 9000
    }
  ]
}

variable "CRIBL_DIST_MASTER_URL" {
  type = string
  description = "<tls|tcp>://<authToken>@host:port?group=defaultGroup&tag=tag1&tag=tag2&tls.<tls-settings below>"
}

variable "desired_count" {
  type = number
  default = 1
}

variable "subnets" {
  type = set(string)
}

variable "security_groups" {
  type = set(string)
  default = null
}