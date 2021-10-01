# Cribl LogStream Leader Module

Variables required:

* `vpc_id`
* `subnet`

Optional variables:

* `instance_type`
* `key_name`
* `sg_ports`

Outputs:

* `logstream_leader_ip` (for use with the logstream_worker module)

Example usage:

```
module "leader" {
  source = "git::https://github.com/bdalpe/cribl-terraform.git//cribl-leader"
  vpc = "vpc-abcdef1234567890"
  subnet = "subnet-abcdef1234567890"
}
```