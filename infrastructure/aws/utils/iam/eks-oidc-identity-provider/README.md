# AWS EKS OIDC Identity Provider Module

Creates an AWS IAM OIDC Identity Provider based on a EKS cluster name.

## Example

```terraform
module "eks_odic_provider" {
  source           = "./infrastructure/aws/utils/iam/eks-oidc-identity-provider"
  eks_cluster_name = "your-cluster-name"
}
```

## Outputs

* `oidc_identity_provider_arn` - The ARN of the created OIDC Identity Provider.
* `issuer` - The EKS OIDC issuer attribute (leading `https://` removed). Useful for IAM Roles.