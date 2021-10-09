resource "random_string" "random" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_ecs_cluster" "fargate_cluster" {
  name = "cribl-logstream-fargate-wg-${random_string.random.result}"

  capacity_providers = ["FARGATE"]
}

data "aws_iam_policy_document" "ecs_tasks_execution_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_tasks_exeuction_role" {
  name = "cribl-logstream-fargate-wg-${random_string.random.result}-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_execution_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_tasks_execution_role" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_tasks_exeuction_role.name
}

resource "aws_cloudwatch_log_group" "fargate_log_group" {
  name = "/aws/ecs/cribl-logstream-fargate-wg-${random_string.random.result}"

  retention_in_days = 7
}

resource "aws_ecs_task_definition" "logstream_worker_task_defintion" {
  family = "cribl-logstream-worker-${random_string.random.result}"
  container_definitions = jsonencode([{
    name = "logstream"
    image = "cribl/cribl:${var.logstream_version}",
    cpu = 4096,
    memory = 16384,
    essential = true,
    mountPoints = []
    portMappings = var.port_mappings,
    environment = [
      {name = "CRIBL_DIST_MASTER_URL", value = var.CRIBL_DIST_MASTER_URL}
    ]
    ulimits = [
      {name = "nofile", hardLimit = 65536, softLimit = 65536}
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group = aws_cloudwatch_log_group.fargate_log_group.name
        awslogs-region = "us-west-2"
        awslogs-stream-prefix = "cribl"
      }
    }
  }])
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = 4096
  memory = 16384
  execution_role_arn = aws_iam_role.ecs_tasks_exeuction_role.arn
}

resource "aws_ecs_service" "logstream_worker_fargate_service" {
  name = "cribl-logstream-fargate-wg-${random_string.random.result}"
  launch_type = "FARGATE"
  cluster = aws_ecs_cluster.fargate_cluster.id
  task_definition = aws_ecs_task_definition.logstream_worker_task_defintion.arn
  desired_count = var.desired_count

  network_configuration {
    subnets = var.subnets
    security_groups = var.security_groups
    assign_public_ip = true
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  # TODO: Load Balancer
#  load_balancer {
#    container_name = ""
#    container_port = 0
#  }
}

# TODO: Finish Auto Scaling variable configs
resource "aws_iam_role" "ecs-autoscale-role" {
  name = "ecs-scale-application"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "application-autoscaling.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-autoscale" {
  role = aws_iam_role.ecs-autoscale-role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
}

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 2
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.fargate_cluster.name}/${aws_ecs_service.logstream_worker_fargate_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  role_arn           = aws_iam_role.ecs-autoscale-role.arn
}

resource "aws_appautoscaling_policy" "ecs_target_cpu" {
  name               = "application-scaling-policy-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 80
  }
  depends_on = [aws_appautoscaling_target.ecs_target]
}

# TODO: Memory-based autoscale
#resource "aws_appautoscaling_policy" "ecs_target_memory" {
#  name               = "application-scaling-policy-memory"
#  policy_type        = "TargetTrackingScaling"
#  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
#  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
#  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace
#
#  target_tracking_scaling_policy_configuration {
#    predefined_metric_specification {
#      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
#    }
#    target_value = 80
#  }
#  depends_on = [aws_appautoscaling_target.ecs_target]
#}