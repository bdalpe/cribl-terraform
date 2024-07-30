resource "random_id" "this" {
  byte_length = 4
}

locals {
  name = join("-", [var.prefix, random_id.this.hex])
}

module "service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 5.11"

  cluster_arn = var.cluster_arn

  desired_count      = var.desired_count
  cpu                = var.cpu
  memory             = var.memory
  memory_reservation = coalesce(var.memory_reservation, var.memory)
  runtime_platform = {
    cpu_architecture = var.cpu_architecture
  }

  subnet_ids       = toset(var.subnet_ids)
  assign_public_ip = var.assign_public_ip

  enable_cloudwatch_logging              = var.cloudwatch_enable
  cloudwatch_log_group_retention_in_days = var.cloudwatch_retention_in_days

  # Container definition(s)
  container_definitions = {
    (local.name) = {
      cpu       = var.cpu
      memory    = var.memory
      essential = true
      image     = join(":", [var.cribl_image_repository, var.cribl_image_version])

      port_mappings = [
        for k, v in var.ports : {
          name          = k
          containerPort = v.container_port,
          protocol      = v.protocol
        }
      ]

      health_check = var.health_check

      environment = [
        {
          name  = "CRIBL_DIST_MODE"
          value = "worker"
        },
        {
          name  = "CRIBL_DIST_MASTER_URL"
          value = var.cribl_dist_master_url
        },
        {
          name  = "CRIBL_VOLUME_DIR"
          value = var.cribl_config_volume_dir
        },
        {
          name  = "CRIBL_TMP_DIR"
          value = var.cribl_tmp_dir
        },
        {
          for k, v in var.environment : k => v
        }
      ]

      enable_cloudwatch_logging = var.cloudwatch_enable

      mount_points = [
        {
          sourceVolume  = "config-volume"
          containerPath = var.cribl_config_volume_dir
        },
        {
          sourceVolume  = "tmp"
          containerPath = var.cribl_tmp_dir
        },
        {
          for k, v in var.mount_points : k => v
        }
      ]
    }
  }

  volume = [
    { name = "config-volume" },
    { name = "tmp" },
    {
      for k, v in var.volumes : k => v
    }
  ]

  #
  # Autoscaling
  #
  enable_autoscaling       = var.autoscaling_enabled
  autoscaling_min_capacity = var.autoscaling_min_capacity
  autoscaling_max_capacity = var.autoscaling_max_capacity
  autoscaling_policies = {
    cpu = {
      policy_type = "TargetTrackingScaling"

      target_tracking_scaling_policy_configuration = {
        target_value       = var.autoscaling_target_cpu
        scale_in_cooldown  = var.autoscaling_cooldown_scale_in_time
        scale_out_cooldown = var.autoscaling_cooldown_scale_out_time

        predefined_metric_specification = {
          predefined_metric_type = "ECSServiceAverageCPUUtilization"
        }
      }
    }
  }

  #
  # Load Balancer
  #
  load_balancer = {
    for k, v in var.ports : k => {
      target_group_arn = v.target_group_arn
      container_name   = local.name
      container_port   = v.container_port
    } if v.target_group_arn
  }

  #
  # Security Group
  #
  security_group_rules = merge(
    {
      for k, v in var.ports : k => {
        type                     = "ingress"
        from_port                = v.container_port
        to_port                  = v.container_port
        protocol                 = v.protocol
        description              = "Inbound connection to ${v.protocol}/${v.container_port}"
        source_security_group_id = lookup(v, "source_security_group_id", null)
        cidr_blocks              = lookup(v, "cidr_blocks", null)
        ipv6_cidr_blocks         = lookup(v, "ipv6_cidr_blocks", null)
        self                     = lookup(v, "self", null)
      }
    },
    {
      for k, v in var.security_group_additional_ingress_rules : k => v
    },
    {
      for k, v in var.security_group_egress_rules : k => {
        type             = "egress"
        from_port        = v.from_port
        to_port          = v.to_port
        protocol         = v.protocol
        cidr_blocks      = lookup(v, "cidr_blocks", null)
        ipv6_cidr_blocks = lookup(v, "ipv6_cidr_blocks", null)
        self             = lookup(v, "self", null)
      }
    }
  )
}
