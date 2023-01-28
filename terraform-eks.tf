
locals {
  cluster_name   = "kojitechs-cluster"
  public_subnet  = module.vpc.public_subnets
  private_subnet = module.vpc.private_subnets
  eks_nodegroup = {
    pulic_nodegroup = {
      name   = format("%s-%s", var.component_name, "public")
      subnet = slice(local.public_subnet, 0, 3)
    }
  }
}

resource "aws_security_group_rule" "this" {
  description       = "Allow secured port on eks security group group"
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"] # ip
  security_group_id = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
}

# Create AWS EKS Cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = "${var.component_name}-eks-demo"
  role_arn = aws_iam_role.eks_master_role.arn
  version  = var.cluster_version # ToDo

  vpc_config {
    subnet_ids              = local.public_subnet
    endpoint_private_access = var.cluster_endpoint_private_access      # ToDo
    endpoint_public_access  = var.cluster_endpoint_public_access       # ToDo
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs # ToDo

  }

  kubernetes_network_config {
    service_ipv4_cidr = var.cluster_service_ipv4_cidr # ToDo
  }

  # Enable EKS Cluster Control Plane Logging
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.eks-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKSVPCResourceController,
  ]
}

# CREATE EKS CLUSTER WORKER NODES
resource "aws_eks_node_group" "eks_nodegroup" {
  for_each = {
    for id, eks_nodegroup in local.eks_nodegroup : id => eks_nodegroup
  }
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = each.value.name
  node_role_arn   = aws_iam_role.eks_nodegroup_role.arn
  subnet_ids      = each.value.subnet

  ami_type       = "AL2_x86_64"
  capacity_type  = "ON_DEMAND"
  disk_size      = 20
  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks-AmazonEC2ContainerRegistryReadOnly,
  ]
  tags = {
    "Name" = each.key
  }
}
