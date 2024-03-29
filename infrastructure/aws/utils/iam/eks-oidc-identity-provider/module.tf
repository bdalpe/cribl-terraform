terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.2"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 3.1"
    }
  }
}

data "aws_eks_cluster" "eks_cluster" {
  name = var.eks_cluster_name
}

data "tls_certificate" "eks" {
  # Generate SHA-1 fingerprint of SSL certificate
  url = data.aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks_oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = data.aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer

  lifecycle {
    ignore_changes = [tags, tags_all]
    prevent_destroy = true
  }
}