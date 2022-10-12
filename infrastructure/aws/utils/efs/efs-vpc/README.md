# AWS EFS for Cribl Configs

Creates an [AWS Elastic File System](https://aws.amazon.com/efs/), [Access Point](https://docs.aws.amazon.com/efs/latest/ug/efs-access-points.html), and [Mount Targets](https://docs.aws.amazon.com/efs/latest/ug/accessing-fs.html) inside the VPC where the EKS cluster is running.

## Example

```terraform
module "efs_vpc" {
  source           = "./infrastructure/aws/utils/efs/efs-vpc"
  eks_cluster_name = "your-cluster-name"
}
```

## Inputs

* `eks_cluster_name` - The name of the EKS cluster.

## Outputs

* `efs_id` - The EFS ID
* `efs_ap_id` - The EFS Access Point ID