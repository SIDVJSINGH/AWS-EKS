locals {
  role-name = "eks-cluster"
  az-1      = "ap-northeast-1a"
  az-2      = "ap-northeast-1c"
  az-3      = "ap-northeast-1d"
  scg       = "AWS-Security"
  def_tags  = "allowed by siddhant"
}

# -------- FOR EKS Cluster---------------------
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Role creation with no policy attached
resource "aws_iam_role" "Role" {
  name               = local.role-name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Power User policy attached
resource "aws_iam_role_policy_attachment" "Power_User" {
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
  role       = aws_iam_role.Role.name
}

# EKS policy attached
resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.Role.name
}

# VPC policy attached
resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.Role.name
}
#-----------------------------------------

#---------- FOR NODE GROUP -------------------
data "aws_iam_policy_document" "ec2_role" {
  statement {
    effect = "Allow"

    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}

# Role creation with no policy attached
resource "aws_iam_role" "ec2role" {
  name               = "eks-node-group"
  assume_role_policy = data.aws_iam_policy_document.ec2_role.json
}

# EKS worker node policy attached
resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.ec2role.name
}

# EKS CNI policy attached : it can change VPC IP for the worker nodes
resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.ec2role.name
}

# EC2 Container Registory Read Only policy attached
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.ec2role.name
}

# Power User Access policy attached
resource "aws_iam_role_policy_attachment" "Admin" {
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
  role       = aws_iam_role.ec2role.name
}
#-----------------------------------------------------------