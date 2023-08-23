# minimum 1 VPC needed for the cluster
resource "aws_vpc" "virtual" {
  cidr_block = "10.0.0.0/16"
}

# minimum 2 subnet in this VPC needed for the cluster
resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.virtual.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = local.az-1
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.virtual.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = local.az-2
}

# 3rd is optional
resource "aws_subnet" "subnet3" {
  vpc_id            = aws_vpc.virtual.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = local.az-3
}
