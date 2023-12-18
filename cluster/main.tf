locals {
  # can't use for_each with modules, create groups here
  #
  # https://docs.amazonaws.cn/en_us/AWSCloudFormation/latest/UserGuide/aws-resource-eks-nodegroup.html
  # "If you specify launchTemplate, and your launch template uses a custom AMI, then don't specify amiType, or the node group deployment will fail."
  eks_managed_node_groups = { for sub in data.terraform_remote_state.vpc.outputs.private_subnets :
    trim(format("%s", sub), "subnet-id-") => {
      min_size     = 1
      max_size     = 1
      desired_size = 1
      # use SPOT to save money if you can handle frequent interruptions
      capacity_type          = "SPOT"
      ami_type               = "CUSTOM"
      ami_id                 = data.aws_ami.default.id
      custom_ami_id          = data.aws_ami.default.id
      subnet_ids             = [sub]
      create                 = true
      create_launch_template = false
      launch_template_id     = aws_launch_template.ghost-custom.id
      # https://github.com/terraform-aws-modules/terraform-aws-eks/issues/2091
      launch_template_name       = ""
      launch_template_version    = aws_launch_template.ghost-custom.default_version
      use_custom_launch_template = true
      # this is required to attach an existing policy, why?!
      create_iam_role = true
    }
  }
}

data "terraform_remote_state" "vpc" {
  backend = "local"
  config = {
    path = "../vpc/ghost-vpc.tfstate"
  }
}

data "aws_ami" "default" {
  most_recent = true
  name_regex  = "amazon-eks-node-1.23"
  owners      = ["amazon"]
}

# https://github.com/terraform-aws-modules/terraform-aws-eks/pull/997
data "template_file" "launch_template_userdata" {
  template = file("${path.module}/userdata.sh.tpl")

  vars = {
    cluster_name         = var.cluster_name
    endpoint             = module.eks-ghost.cluster_endpoint
    cluster_auth_base64  = module.eks-ghost.cluster_certificate_authority_data
    bootstrap_extra_args = ""
    kubelet_extra_args   = ""
  }
}

resource "aws_iam_policy" "alb-controller" {
  name        = "alb-policy"
  description = "alb controller eks custom policy"

  policy = <<EOT
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreateServiceLinkedRole"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "iam:AWSServiceName": "elasticloadbalancing.amazonaws.com"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
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
                "elasticloadbalancing:DescribeTags"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
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
                "shield:DeleteProtection"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:RevokeSecurityGroupIngress"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateSecurityGroup"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateTags"
            ],
            "Resource": "arn:aws:ec2:*:*:security-group/*",
            "Condition": {
                "StringEquals": {
                    "ec2:CreateAction": "CreateSecurityGroup"
                },
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateTags",
                "ec2:DeleteTags"
            ],
            "Resource": "arn:aws:ec2:*:*:security-group/*",
            "Condition": {
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "true",
                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:RevokeSecurityGroupIngress",
                "ec2:DeleteSecurityGroup"
            ],
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:CreateLoadBalancer",
                "elasticloadbalancing:CreateTargetGroup"
            ],
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:CreateListener",
                "elasticloadbalancing:DeleteListener",
                "elasticloadbalancing:CreateRule",
                "elasticloadbalancing:DeleteRule"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:AddTags",
                "elasticloadbalancing:RemoveTags"
            ],
            "Resource": [
                "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
                "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
                "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
            ],
            "Condition": {
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "true",
                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:AddTags",
                "elasticloadbalancing:RemoveTags"
            ],
            "Resource": [
                "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
                "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
                "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
                "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:ModifyLoadBalancerAttributes",
                "elasticloadbalancing:SetIpAddressType",
                "elasticloadbalancing:SetSecurityGroups",
                "elasticloadbalancing:SetSubnets",
                "elasticloadbalancing:DeleteLoadBalancer",
                "elasticloadbalancing:ModifyTargetGroup",
                "elasticloadbalancing:ModifyTargetGroupAttributes",
                "elasticloadbalancing:DeleteTargetGroup"
            ],
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:RegisterTargets",
                "elasticloadbalancing:DeregisterTargets"
            ],
            "Resource": "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:SetWebAcl",
                "elasticloadbalancing:ModifyListener",
                "elasticloadbalancing:AddListenerCertificates",
                "elasticloadbalancing:RemoveListenerCertificates",
                "elasticloadbalancing:ModifyRule"
            ],
            "Resource": "*"
        }
    ]
}
EOT
}

resource "aws_launch_template" "ghost-custom" {
  # provider      =  aws.failover
  name_prefix            = var.cluster_name
  description            = "Custom launch template for to get AMI"
  update_default_version = true

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 100
      volume_type           = "gp2"
      delete_on_termination = true
    }
  }

  ebs_optimized = true
  image_id      = data.aws_ami.default.id

  monitoring {
    enabled = true
  }

  user_data = base64encode(
    data.template_file.launch_template_userdata.rendered,
  )

  lifecycle {
    create_before_destroy = true
  }

  vpc_security_group_ids = [
    module.eks-ghost.node_security_group_id
  ]
}

module "eks-ghost" {
  source  = "terraform-aws-modules/eks/aws"
  version = "<= 19.0"

  cluster_name                   = var.cluster_name
  cluster_endpoint_public_access = true
  iam_role_additional_policies = {
    "ssmcore" : "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "alb" : aws_iam_policy.alb-controller.arn
  }

  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets
  vpc_id     = data.terraform_remote_state.vpc.outputs.vpc_id

  eks_managed_node_group_defaults = {
    instance_types = ["t3.small", "t2.small"]
  }
  eks_managed_node_groups = local.eks_managed_node_groups

  #create_aws_auth_configmap = true
  #manage_aws_auth_configmap = true

  aws_auth_users = var.aws_auth_users
}


#provider "kubernetes" {
#  host                   = module.eks-ghost.cluster_endpoint
#  cluster_ca_certificate = base64decode(module.eks-ghost.cluster_certificate_authority_data)

#  exec {
#    api_version = "client.authentication.k8s.io/v1beta1"
#    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
#    command     = "aws"
#  }
#}
