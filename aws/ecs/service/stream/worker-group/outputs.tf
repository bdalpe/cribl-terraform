output "name" {
  description = "Cribl Worker Group Service Name"
  value = local.name
}

# Descriptions of output values nested under service can be found here:
# https://github.com/terraform-aws-modules/terraform-aws-ecs/blob/master/modules/service/outputs.tf
output "service" {
  description = "ECS Service configuration"
  value = module.service
}

