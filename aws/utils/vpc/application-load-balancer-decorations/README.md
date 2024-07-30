# AWS EKS Application Load Balancer VPC Tag Decorator

Adds appropriate tags to VPC subnets used by the EKS ALB Controller for [subnet auto discovery](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.1/deploy/subnet_discovery/).

## Example

```terraform
module "eks_alb_vpc_decorator" {
  source           = "./infrastructure/aws/utils/vpc/application-load-balancer-decorations"
  eks_cluster_name = "your-cluster-name"
}
```

## Inputs

* `eks_cluster_name` - The name of the EKS cluster.
* `cluster_subnet_type` - `shared` or `owned`
* `internal_elb` - `bool` Determines whether an internet-facing or internal LB is deployed.

## Outputs

None