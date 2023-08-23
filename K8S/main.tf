resource "aws_eks_cluster" "K8S" {
  name     = "K8S-Cluster"
  role_arn = aws_iam_role.Role.arn

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController,
    aws_iam_role_policy_attachment.Power_User
  ]
  vpc_config {
    subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id, aws_subnet.subnet3.id]

    endpoint_public_access  = true
    endpoint_private_access = false

  }
  #  outpost_config {
  #    control_plane_instance_type = "t2.micro"
  #    outpost_arns                = ["arn:aws:outposts:region:account-id:outpost/outpost-id"]
  #  }

  timeouts {
    create = "10m"
    delete = "5m"
    update = "10m"
  }
}

resource "aws_eks_node_group" "nodes" {
  node_group_name = "K8S-group"
  cluster_name    = aws_eks_cluster.K8S.name
  node_role_arn   = aws_iam_role.ec2role.arn
  subnet_ids      = [aws_subnet.subnet1.id, aws_subnet.subnet2.id, aws_subnet.subnet3.id]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  launch_template {
    version = "latest"
  }

  instance_types       = ["t3.small","m5.small"]
  disk_size            = 20
  capacity_type        = "ON_DEMAND"
  force_update_version = false

  update_config {
    max_unavailable_percentage = 90
  }
  ami_type = "AL2_x86_64"

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.Admin
  ]
  timeouts {
    create = "15m"
    delete = "5m"
    update = "10m"
  }
}

# ingress = incoming
# egress  = outgoing
# TCP port = 443 (HTTPS)
# TCP port = 22 (SSH - secure shell)
# UDP port = 69 (TFTP - Trivial File Transfer Protocol)
# UCP and TCP port = 80 (HTTP)
# TCP port = 27017 (for MongoDB)

resource "aws_security_group" "security" {
  name   = local.scg
  vpc_id = aws_vpc.virtual.id

  #  ingress {
  #    description = "SSH"
  #    from_port   = 22
  #    to_port     = 22
  #    protocol    = "TCP"
  #    cidr_blocks = ["0.0.0.0/0"] # anywhere/public
  #  }
  #  ingress {
  #    description = "HTTP for TCP and UDP"
  #    from_port   = 80
  #    to_port     = 80
  #    protocol    = "TCP"
  #    cidr_blocks = ["0.0.0.0/0"] # anywhere/public
  #  }
  #  ingress {
  #    description = "HTTPS for TCP"
  #    from_port   = 443
  #    to_port     = 443
  #    protocol    = "TCP"
  #    cidr_blocks = ["0.0.0.0/0"] # anywhere/public
  #  }

  # Dynamic block for above Security group ingress

  dynamic "ingress" {
    for_each = [80, 443, 22]
    iterator = port
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = {
    name = "${local.def_tags}"
  }
}

output "security_grp_id" {
  value = aws_security_group.security.id
}

output "endpoint" {
  value = aws_eks_cluster.K8S.endpoint
}

resource "aws_cloudwatch_metric_alarm" "watchme" {
  alarm_name          = "Watch-Me"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization" # for EC2 CPU Utilization
  namespace           = "AWS/EKS"
  period              = 60
  statistic           = "Average"
  threshold           = 50 # alarm will trigger when 50% CPU is utilized

  alarm_description = "CPU utilization alarm for EKS cluster"
  dimensions = {
    ClusterName = aws_eks_cluster.K8S.name
  }
}
