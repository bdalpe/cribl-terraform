# Cribl LogStream Leader Module

Variables required:

* `vpc_id`
* `subnet`

Optional variables:

* `instance_type`
* `key_name`
* `sg_ports`

Example usage:

```
module "leader" {
  source = "git::https://github.com/bdalpe/cribl-terraform.git//cribl-leader"
  vpc = "vpc-abcdef1234567890"
  subnet = "subnet-abcdef1234567890"
}
```