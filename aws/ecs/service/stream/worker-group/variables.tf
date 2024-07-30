variable "cluster_arn" {
  type = string
}

variable "prefix" {
  type    = string
  default = "cribl-workergroup-fargate"
}

variable "subnet_ids" {
  type = set(string)
}

variable "cribl_image_repository" {
  type    = string
  default = "public.ecr.aws/cribl/cribl"
}

variable "cribl_image_version" {
  type    = string
  default = "4.7.3"
}

variable "cribl_dist_master_url" {
  type      = string
  sensitive = true
  validation {
    condition     = regex("^(tcp|tls)?://[-a-zA-Z0-9@:%._\\+~#=]{1,256}@[-a-zA-Z0-9@:%._\\+~#=]{1,256}(?:(\\?|\\&)([^=]+)\\=([^&]+)){0,}$", var.cribl_dist_master_url)
    error_message = "CRIBL_DIST_MASTER_URL is invalid. Consult the Cribl Environment Variable docs for more information."
  }
}

variable "cribl_config_volume_dir" {
  type    = string
  default = "/opt/cribl/config-volume"
}

variable "cribl_tmp_dir" {
  type    = string
  default = "/tmp/cribl"
}

variable "cpu" {
  type    = number
  default = 4096
}

variable "memory" {
  type    = number
  default = 8192
}

variable "memory_reservation" {
  type    = number
  nullable = true
}

variable "cpu_architecture" {
  type    = string
  default = "ARM64"
  validation {
    condition     = contains(["AMR64", "X86_64"], var.cpu_architecture)
    error_message = "cpu_architecture must be one of [ARM64, X86_64]"
  }
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "assign_public_ip" {
  type    = bool
  default = true
}

variable "environment" {
  type = map(
    object(
      {
        name = string
        value = string
      }
    )
  )

  default = {}
}

variable "mount_points" {
  type = any
  default = {}
}

variable "volumes" {
  type = any
  default = {}
}

variable "autoscaling_enabled" {
  type    = bool
  default = false
}

variable "autoscaling_target_cpu" {
  type    = number
  default = 80
}

variable "autoscaling_cooldown_scale_out_time" {
  type    = number
  default = 60
}

variable "autoscaling_cooldown_scale_in_time" {
  type    = number
  default = 300
}

variable "autoscaling_min_capacity" {
  type    = number
  default = 2
}

variable "autoscaling_max_capacity" {
  type    = number
  default = 10
}

variable "ports" {
  type = map(
    object(
      {
        container_port           = number
        protocol                 = string
        target_group_arn         = optional(string)
        source_security_group_id = optional(string)
        cidr_blocks              = optional(set(string))
        ipv6_cidr_blocks         = optional(set(string))
      }
    )
  )

  default = {
    api = {
      container_port   = 9000
      listenPort       = 9000
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::0/0"]
    }
  }
}

variable "security_group_additional_ingress_rules" {
  type = any
  default = {}
}

variable "security_group_egress_rules" {
  type = map(
    object(
      {
        from_port = number
        to_port = number
        protocol = string
        self = bool
        cidr_blocks = optional(set(string))
        ipv6_cidr_blocks = optional(set(string))
      }
    )
  )
}

variable "cloudwatch_enable" {
  type    = bool
  default = true
}

variable "cloudwatch_retention_in_days" {
  type    = number
  default = 7
}

variable "health_check" {
  type = object(
    {
      command  = list(string)
      interval = number
      retry    = number
      timeout  = number
    }
  )

  default = {
    command  = ["CMD-SHELL", "curl -f http://localhost:9000/api/v1/health || exit 1"]
    interval = 10
    retry    = 6
    timeout  = 5
  }
}
