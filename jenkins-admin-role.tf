data "aws_caller_identity" "current" {}

resource "aws_iam_role" "jenkins_ssm_fleet_ec2" {
  name = "${var.component_name}-jenkins-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "jenkins_instance_profile" {
  name = "${var.component_name}-jenkins-profile"
  role = aws_iam_role.jenkins_ssm_fleet_ec2.name
}

resource "aws_iam_policy" "this" {
  name        = "${var.component_name}-jenkins-policy"
  description = "Access  policy for jenkins server to ssm fleet"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
          "ec2:*",
          "ec2messages:*",
          "ecr:*",
          "ecs:*",
          "elasticfilesystem:*",
          "elasticache:*",
          "elasticloadbalancing:*",
          "es:*",
          "events:*",
          "iam:*",
          "kms:*",
          "lambda:*",
          "logs:*",
          "rds:*",
          "route53:*",
          "ssm:*",
          "ssmmessages:*",
          "secretsmanager:*",
          "s3:*",
          "dynamodb:*",
          "acm:*",
          "sns:*",
          "sqs:*",
          "eks:*",
          "ec2:DescribeNetworkInterfaces",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeInstances",
          "ec2:AttachNetworkInterface"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ec2_policy_attach" {
  role       = aws_iam_role.jenkins_ssm_fleet_ec2.name
  policy_arn = aws_iam_policy.this.arn
}

# Resource: k8s Cluster Role
resource "kubernetes_cluster_role_v1" "eksdeveloper_clusterrole" {
  metadata {
    name = "${var.component_name}-eksdeveloper-clusterrole"
  }

  rule {
    api_groups = [""]
    #resources  = ["nodes", "namespaces", "pods", "events", "services"]
    resources = ["nodes", "namespaces", "pods", "events", "services", "configmaps", "serviceaccounts"] #Uncomment for additional Testing
    verbs     = ["*"]
  }
  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "daemonsets", "statefulsets", "replicasets"]
    verbs      = ["*"]
  }
  rule {
    api_groups = ["batch"]
    resources  = ["jobs"]
    verbs      = ["*"]
  }
}

# Resource: k8s Cluster Role Binding
resource "kubernetes_cluster_role_binding_v1" "eksdeveloper_clusterrolebinding" {
  metadata {
    name = "${var.component_name}-eksdeveloper-clusterrolebinding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.eksdeveloper_clusterrole.metadata.0.name
  }
  subject {
    kind      = "Group"
    name      = "eks-developer-group"
    api_group = "rbac.authorization.k8s.io"
  }
}

locals {
  configmap_roles = [
    {
      rolearn  = "${aws_iam_role.eks_nodegroup_role.arn}"
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    },
    {
      rolearn  = "${aws_iam_role.jenkins_ssm_fleet_ec2.arn}"
      username = "jenkins-admin"
      groups   = ["system:masters"]
    },
  ]
}

# Resource: Kubernetes Config Map
resource "kubernetes_config_map_v1" "aws_auth" {
  depends_on = [
    aws_eks_cluster.eks_cluster,
    #kubernetes_cluster_role_v1.eksreadonly_clusterrolebinding,
    kubernetes_cluster_role_binding_v1.eksdeveloper_clusterrolebinding,
    #kubernetes_role_binding_v1.eksdeveloper_rolebinding
  ]
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
  data = {
    mapRoles = yamlencode(local.configmap_roles)
  }
}
