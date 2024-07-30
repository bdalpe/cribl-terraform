# AWS ECS Fargate - Cribl Worker Group

This module creates an ECS service for a Cribl Worker Group. For example, you could deploy a group of Cribl Stream Workers on ECS Fargate.

This module does not create an ECS cluster (required) or Load Balancer (optional) resources.

## Basic Example

```terraform
module "cribl_worker_group" {
  source = "git::https://github.com/bdalpe/cribl-terraform.git//aws/ecs/service/stream/worker-group"
  
  cluster_arn = "arn:aws:ecs:us-west-2:123456789012:cluster/cribl"
  subnet_ids = ["subnet-1234567890abcdef0", "subnet-1234567890abcdef1"]
  cribl_dist_master_url = "tls://<token>@leader.example.com:4200?group=fargate"
}
```

## Outputs

| Name                                       | Description                                        |
|--------------------------------------------|----------------------------------------------------|
| <a name="name"></a> [name](#name)          | Cribl Worker Group Service Name                    | 
| <a name="service"></a> [service](#service) | The nested output of the ECS Service configuration |

## Full Example

```terraform
locals {
  vpc = "vpc-12345678"
  subnet_ids = ["subnet-1234567890abcdef0", "subnet-1234567890abcdef1"]
  ports = {
    api = {
      container_port = 9000
      protocol = "tcp"
    }
    syslog = {
      container_port = 9514
      protocol = "tcp"
    }
  }
}

module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.11"

  cluster_name = "cribl-workers-fargate"

  default_capacity_provider_use_fargate = true
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
      }
    }
  }
}

module "cribl_worker_group" {
  source = "git::https://github.com/bdalpe/cribl-terraform.git//aws/ecs/service/stream/worker-group"
  
  cluster_arn = module.ecs.cluster_arn
  subnet_ids = local.subnet_ids
  cribl_dist_master_url = "tls://<token>@leader.example.com:4200?group=fargate"
  
  ports = {
    for k, v in local.ports : k => {
      container_port   = v.container_port
      protocol         = v.protocol
      target_group_arn = module.nlb.target_group_arn[k].arn
    }
  }
}

module "nlb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.10.0"

  name               = "cribl-worker-nlb"
  load_balancer_type = "network"
  internal           = true
  vpc_id             = local.vpc
  subnets            = local.subnet_ids

  security_group_ingress_rules = {
    for k, v in local.ports : k => {
      from_port   = v.container_port
      to_port     = v.container_port
      ip_protocol = v.protocol
      description = "Allow inbound connection on port ${coalesce(v.listen_port, v.container_port)}"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }

    listeners = {
      for k, v in local.ports : k => {
        port = v.container_port
        protocol = upper(v.protocol)
        forward = {
          target_group_key = k
        }
      }
    }

    target_groups = {
      for k, v in local.ports : k => {
        target_type                       = "ip"
        protocol = upper(v.protocol)
        port                              = v.containerPort
        deregistration_delay              = 5
        load_balancing_cross_zone_enabled = true

        health_check = {
          enabled             = true
          healthy_threshold   = 5
          interval            = 10
          matcher             = "200"
          path                = "/api/v1/health"
          port                = 9000
          timeout             = 5
          unhealthy_threshold = 2
        }

        create_attachment = false
      }
    }
  }
}
```
