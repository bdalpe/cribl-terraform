data "aws_eks_cluster" "cluster" {
  name = var.eks_cluster_name
}

resource "aws_ec2_tag" "subnet_cluster" {
  for_each = data.aws_eks_cluster.cluster.vpc_config[0].subnet_ids
  resource_id = each.value
  key = "kubernetes.io/cluster/${var.eks_cluster_name}"
  value = var.cluster_subnet_type
}

resource "aws_ec2_tag" "subnet_alb_type" {
  for_each = data.aws_eks_cluster.cluster.vpc_config[0].subnet_ids
  resource_id = each.value
  key = "kubernetes.io/role/${var.internal_elb ? "internal-elb" : "elb"}"
  value = "1"
}