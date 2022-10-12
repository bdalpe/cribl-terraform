variable "eks_cluster_name" {
  type = string
}

variable "efs_id" {
  type = string
}

variable "efs_ap_id" {
  type = string
}

variable "k8s_pv_name" {
  type = string
  default = "cribl-stream-efs-pv"
}

variable "storage_class_name" {
  type = string
  default = "efs-sc"
}

variable "capacity" {
  type = string
  default = "25Gi"
}