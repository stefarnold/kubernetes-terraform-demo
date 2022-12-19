locals {
  all_azs = toset(data.aws_availability_zones.available.names)
  # https://registry.terraform.io/modules/cloudposse/dynamic-subnets/aws/latest
  existing_az_count = length(data.aws_availability_zones.available.names)
  cidr_count        = local.existing_az_count * 2
  subnet_bits       = ceil(log(local.cidr_count, 2))
  cidr_block        = var.cidr_block
  priv_cidrs        = [for netnumber in range(0, local.existing_az_count) : cidrsubnet(local.cidr_block, local.subnet_bits, netnumber)]
  pub_cidrs         = [for netnumber in range(local.existing_az_count, local.cidr_count) : cidrsubnet(local.cidr_block, local.subnet_bits, netnumber)]
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = "wm-case-study"

  azs                  = local.all_azs
  cidr                 = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = true

  private_subnets = local.priv_cidrs
  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared",
    "kubernetes.io/role/internal-elb"           = "1"
  }

  public_subnets = local.pub_cidrs
  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared",
    "kubernetes.io/role/elb"                    = "1"
  }
}

resource "aws_security_group" "web" {
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "443"
    to_port     = "443"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}