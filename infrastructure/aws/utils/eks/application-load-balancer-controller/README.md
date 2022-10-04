# AWS EKS Application Load Balancer Controller

Installs the [AWS EKS Application Load Balancer Controller](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html) add-on into the Kubernetes cluster including the appropriate IAM roles and permissions.

This module assumes you've already provisioned an AWS IAM OIDC Identity Provider for your Kubernetes cluster. (you can provision one using [another module in this repository](../../iam/eks-oidc-identity-provider))

## Example

```terraform
module "eks_alb_controller" {
  source           = "./infrastructure/aws/utils/eks/application-load-balancer-controller"
  eks_cluster_name = "your-cluster-name"
}
```

## Inputs

* `eks_cluster_name` - The name of the EKS cluster.
* `imageRepository` - (optional) the Docker Repository URL. Defaults to the Amazon container image registry for the EKS ALB Controller.

## Outputs

None