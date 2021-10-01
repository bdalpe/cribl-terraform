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

resource "aws_security_group" "leader" {
  name        = "cribl-logstream-leader-${random_string.random.result}"
  description = "Cribl LogStream Leader Security Group"

  vpc_id = var.vpc

  lifecycle {
    ignore_changes = [tags]
  }

  dynamic "ingress" {
    for_each = var.sg_ports

    content {
      from_port        = ingress.key
      to_port          = ingress.key
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      description      = ingress.value
    }
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_instance" "leader" {
  ami           = data.aws_ami.amzn2_ami.id
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = var.subnet

  vpc_security_group_ids = [
    aws_security_group.leader.id
  ]

  tags = {
    Name = "Cribl LogStream Leader"
  }

  lifecycle {
    ignore_changes = [tags]
  }
}