variable "eks_cluster_name" {
  type = string
}

variable "cluster_subnet_type" {
  type = string
  validation {
    condition = contains(["shared", "owned"], var.cluster_subnet_type)
    error_message = "Please specify a valid Cluster subnet type (shared or owned)"
  }
}

variable "internal_elb" {
  type = bool
  default = false
}