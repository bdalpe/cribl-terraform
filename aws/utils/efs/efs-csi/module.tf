terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.7"
    }
  }
}

data "aws_eks_cluster" "eks_cluster" {
  name = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "eks_auth_token" {
  name = var.eks_cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  token = data.aws_eks_cluster_auth.eks_auth_token.token
}

resource "kubernetes_storage_class" "efs-sc" {
  metadata {
    name = var.storage_class_name
  }

  storage_provisioner = "efs.csi.aws.com"
}

resource "kubernetes_persistent_volume" "cribl_stream_config_pv" {
  metadata {
    name = var.k8s_pv_name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    capacity = {
      storage = var.capacity
    }
    persistent_volume_source {
      csi {
        driver        = "efs.csi.aws.com"
        volume_handle = "${var.efs_id}::${var.efs_ap_id}"
      }
    }
    persistent_volume_reclaim_policy = "Retain"
    volume_mode                      = "Filesystem"
    storage_class_name               = var.storage_class_name
  }
}