terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.7"
    }
    helm = {
      source = "hashicorp/helm"
      version = "~> 2.7.0"
    }
  }
}

data "aws_eks_cluster" "eks_cluster" {
  name = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "eks_auth_token" {
  name = var.eks_cluster_name
}

data "aws_region" "region" {}

data "aws_iam_openid_connect_provider" "eks_oidc_provider" {
  url = data.aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

data "aws_iam_policy_document" "EKSAWSLoadBalancerControllerIAMAssumeRolePolicy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_iam_openid_connect_provider.eks_oidc_provider.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_iam_openid_connect_provider.eks_oidc_provider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.eks_oidc_provider.arn]
    }
  }
}

resource "aws_iam_role" "EKSAWSLoadBalancerControllerIAMRole" {
  name = "EKSAWSLoadBalancerControllerIAMRole"
  assume_role_policy = data.aws_iam_policy_document.EKSAWSLoadBalancerControllerIAMAssumeRolePolicy.json
}

resource "aws_iam_policy_attachment" "lb-role-attachement" {
  name       = "EKSAWSLoadBalancerControllerIAMPolicy"
  policy_arn = aws_iam_policy.EKSAWSLoadBalancerControllerIAMPolicy.arn
  roles = [aws_iam_role.EKSAWSLoadBalancerControllerIAMRole.name]
}

resource "aws_iam_policy" "EKSAWSLoadBalancerControllerIAMPolicy" {
  name = "EKSAWSLoadBalancerControllerIAMPolicy"
  policy = data.aws_iam_policy_document.EKSAWSLoadBalancerControllerIAMPolicy.json
}

data "aws_iam_policy_document" "EKSAWSLoadBalancerControllerIAMPolicy" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = ["iam:CreateServiceLinkedRole"]

    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values   = ["elasticloadbalancing.amazonaws.com"]
    }
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeVpcs",
      "ec2:DescribeVpcPeeringConnections",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeInstances",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeTags",
      "ec2:GetCoipPoolUsage",
      "ec2:DescribeCoipPools",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeListenerCertificates",
      "elasticloadbalancing:DescribeSSLPolicies",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:DescribeTags",
    ]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "cognito-idp:DescribeUserPoolClient",
      "acm:ListCertificates",
      "acm:DescribeCertificate",
      "iam:ListServerCertificates",
      "iam:GetServerCertificate",
      "waf-regional:GetWebACL",
      "waf-regional:GetWebACLForResource",
      "waf-regional:AssociateWebACL",
      "waf-regional:DisassociateWebACL",
      "wafv2:GetWebACL",
      "wafv2:GetWebACLForResource",
      "wafv2:AssociateWebACL",
      "wafv2:DisassociateWebACL",
      "shield:GetSubscriptionState",
      "shield:DescribeProtection",
      "shield:CreateProtection",
      "shield:DeleteProtection",
    ]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
    ]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]
    actions   = ["ec2:CreateSecurityGroup"]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["arn:aws:ec2:*:*:security-group/*"]
    actions   = ["ec2:CreateTags"]

    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values   = ["CreateSecurityGroup"]
    }

    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["arn:aws:ec2:*:*:security-group/*"]

    actions = [
      "ec2:CreateTags",
      "ec2:DeleteTags",
    ]

    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values   = ["true"]
    }

    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:DeleteSecurityGroup",
    ]

    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateTargetGroup",
    ]

    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:CreateRule",
      "elasticloadbalancing:DeleteRule",
    ]
  }

  statement {
    sid    = ""
    effect = "Allow"

    resources = [
      "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
      "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
      "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*",
    ]

    actions = [
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:RemoveTags",
    ]

    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values   = ["true"]
    }

    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    sid    = ""
    effect = "Allow"

    resources = [
      "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
      "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
      "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
      "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*",
    ]

    actions = [
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:RemoveTags",
    ]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:SetIpAddressType",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:DeleteTargetGroup",
    ]

    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"]

    actions = [
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets",
    ]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "elasticloadbalancing:SetWebAcl",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:AddListenerCertificates",
      "elasticloadbalancing:RemoveListenerCertificates",
      "elasticloadbalancing:ModifyRule",
    ]
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  token = data.aws_eks_cluster_auth.eks_auth_token.token
}

resource "kubernetes_service_account" "aws-load-balancer-controller" {
  metadata {
    labels = {
      "app.kuberenetes.io" : "controller"
      "app.kubernetes.io" : "aws-load-balancer-controller"
    }
    name = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.EKSAWSLoadBalancerControllerIAMRole.arn
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks_cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks_auth_token.token
  }
}

resource "helm_release" "alb_controller_chart" {
  chart = "aws-load-balancer-controller"
  name  = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  namespace = "kube-system"

  set {
    name = "region"
    value = data.aws_region.region.name
  }

  set {
    name = "vpcId"
    value = data.aws_eks_cluster.eks_cluster.vpc_config[0].vpc_id
  }

  set {
    # https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html
    name = "image.repository"
    value = coalesce(var.imageRepository, lookup({
      af-south-1="877085696533.dkr.ecr.af-south-1.amazonaws.com/amazon/aws-load-balancer-controller",
      ap-east-1="800184023465.dkr.ecr.ap-east-1.amazonaws.com/amazon/aws-load-balancer-controller",
      ap-northeast-1="602401143452.dkr.ecr.ap-northeast-1.amazonaws.com/amazon/aws-load-balancer-controller",
      ap-northeast-2="602401143452.dkr.ecr.ap-northeast-2.amazonaws.com/amazon/aws-load-balancer-controller",
      ap-northeast-3="602401143452.dkr.ecr.ap-northeast-3.amazonaws.com/amazon/aws-load-balancer-controller",
      ap-south-1="602401143452.dkr.ecr.ap-south-1.amazonaws.com/amazon/aws-load-balancer-controller",
      ap-southeast-1="602401143452.dkr.ecr.ap-southeast-1.amazonaws.com/amazon/aws-load-balancer-controller",
      ap-southeast-2="602401143452.dkr.ecr.ap-southeast-2.amazonaws.com/amazon/aws-load-balancer-controller",
      ap-southeast-3="296578399912.dkr.ecr.ap-southeast-3.amazonaws.com/amazon/aws-load-balancer-controller",
      ca-central-1="602401143452.dkr.ecr.ca-central-1.amazonaws.com/amazon/aws-load-balancer-controller",
      cn-north-1="918309763551.dkr.ecr.cn-north-1.amazonaws.com.cn/amazon/aws-load-balancer-controller",
      cn-northwest-1="961992271922.dkr.ecr.cn-northwest-1.amazonaws.com.cn/amazon/aws-load-balancer-controller",
      eu-central-1="602401143452.dkr.ecr.eu-central-1.amazonaws.com/amazon/aws-load-balancer-controller",
      eu-north-1="602401143452.dkr.ecr.eu-north-1.amazonaws.com/amazon/aws-load-balancer-controller",
      eu-south-1="590381155156.dkr.ecr.eu-south-1.amazonaws.com/amazon/aws-load-balancer-controller",
      eu-west-1="602401143452.dkr.ecr.eu-west-1.amazonaws.com/amazon/aws-load-balancer-controller",
      eu-west-2="602401143452.dkr.ecr.eu-west-2.amazonaws.com/amazon/aws-load-balancer-controller",
      eu-west-3="602401143452.dkr.ecr.eu-west-3.amazonaws.com/amazon/aws-load-balancer-controller",
      me-south-1="558608220178.dkr.ecr.me-south-1.amazonaws.com/amazon/aws-load-balancer-controller",
      sa-east-1="602401143452.dkr.ecr.sa-east-1.amazonaws.com/amazon/aws-load-balancer-controller",
      us-east-1="602401143452.dkr.ecr.us-east-1.amazonaws.com/amazon/aws-load-balancer-controller",
      us-east-2="602401143452.dkr.ecr.us-east-2.amazonaws.com/amazon/aws-load-balancer-controller",
      us-gov-east-1="151742754352.dkr.ecr.us-gov-east-1.amazonaws.com/amazon/aws-load-balancer-controller",
      us-gov-west-1="013241004608.dkr.ecr.us-gov-west-1.amazonaws.com/amazon/aws-load-balancer-controller",
      us-west-1="602401143452.dkr.ecr.us-west-1.amazonaws.com/amazon/aws-load-balancer-controller",
      us-west-2="602401143452.dkr.ecr.us-west-2.amazonaws.com/amazon/aws-load-balancer-controller"
    }, data.aws_region.region.name))
  }

  set {
    name  = "clusterName"
    value = var.eks_cluster_name
  }

  set {
    name = "serviceAccount.create"
    value = false
  }

  set {
    name = "serviceAccount.name"
    value = kubernetes_service_account.aws-load-balancer-controller.metadata[0].name
  }
}