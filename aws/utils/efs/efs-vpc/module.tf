terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.2"
    }
  }
}

data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_subnet" "subnets" {
  for_each = toset(data.aws_eks_cluster.cluster.vpc_config[0].subnet_ids)
  id       = each.value
}

# Only one subnet per AZ
# Group Subnets by AZ and then pick the first
# inspired by https://www.acritelli.com/blog/terraform-subnet-per-az/
locals {
  subnets = [for k, v in {
    for availability_zone, subnet in data.aws_subnet.subnets : subnet.availability_zone => subnet.id...
  } : v[0]]
}

resource "aws_efs_file_system" "efs" {
  encrypted        = true
  creation_token   = "Cribl-Configs"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  tags = {
    Name = "CriblConfigs"
  }
}

resource "aws_efs_access_point" "efs_ap" {
  file_system_id = aws_efs_file_system.efs.id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/cribl"

    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = 777
    }
  }
}

resource "aws_efs_mount_target" "mount_target" {
  for_each = toset(local.subnets)

  file_system_id = aws_efs_file_system.efs.id
  subnet_id = each.value

  security_groups = [aws_security_group.efs_sg.id]
}

resource "aws_security_group" "efs_sg" {
  name        = "Cribl-Configs-EFS-SG"
  description = "Allow access to Cribl Config EFS from VPC Subnets"

  vpc_id = data.aws_eks_cluster.cluster.vpc_config[0].vpc_id

  ingress {
    from_port   = 2049
    protocol    = "tcp"
    to_port     = 2049
    cidr_blocks = [for s in data.aws_subnet.subnets : s.cidr_block]
  }
}