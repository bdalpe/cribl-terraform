terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

resource "random_string" "random" {
  length  = 8
  special = false
  upper   = false
}

data "aws_ami" "amzn2_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    # TODO: ARM support
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_subnet" "subnet" {
  id = var.subnet
}

resource "aws_security_group" "leader" {
  name        = "cribl-logstream-leader-${random_string.random.result}"
  description = "Cribl LogStream Leader Security Group"

  vpc_id = var.vpc

  lifecycle {
    ignore_changes = [tags]
  }

  dynamic "ingress" {
    for_each = var.sg_ingress_ports

    content {
      from_port        = ingress.key
      to_port          = ingress.key
      protocol         = ingress.value.protocol
      cidr_blocks      = ingress.value.cidr_blocks
      ipv6_cidr_blocks = ingress.value.ipv6_cidr_blocks
      description      = ingress.value.description
    }
  }

  dynamic "egress" {
    for_each = var.sg_egress_ports

    content {
      from_port        = egress.key
      to_port          = egress.key
      protocol         = egress.value.protocol
      cidr_blocks      = egress.value.cidr_blocks
      ipv6_cidr_blocks = egress.value.ipv6_cidr_blocks
      description      = egress.value.description
    }
  }
}

resource "aws_instance" "leader" {
  ami           = data.aws_ami.amzn2_ami.id
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = var.subnet
  user_data = var.user_data != null ? var.user_data : templatefile("${path.module}/templates/logstream.sh", {})

  metadata_options {
    http_endpoint = "enabled"
    http_tokens = "required" #IMDSv2
  }

  vpc_security_group_ids = [
    aws_security_group.leader.id
  ]

  tags = {
    Name = "Cribl LogStream Leader"
  }

  lifecycle {
    ignore_changes = [tags, tags_all]
  }
}

# Store the $CRIBL_HOME directory on a separate volume
resource "aws_ebs_volume" "logstream_configs_volume" {
  availability_zone = data.aws_subnet.subnet.availability_zone
  size = var.config_volume_size
}

resource "aws_volume_attachment" "logstream_config_volume_attachement" {
  device_name = "/dev/xvdl"
  volume_id = aws_ebs_volume.logstream_configs_volume.id
  instance_id = aws_instance.leader.id
}