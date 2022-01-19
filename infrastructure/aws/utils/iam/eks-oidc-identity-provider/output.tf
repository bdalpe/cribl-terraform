output "oidc_identity_provider_arn" {
  value = aws_iam_openid_connect_provider.eks_oidc.arn
}

output "issuer" {
  value = aws_iam_openid_connect_provider.eks_oidc.url
}