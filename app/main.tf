
data "terraform_remote_state" "cluster-state" {
  backend = "local"
  config = {
    path = "../cluster/ghost-eks.tfstate"
  }
}

data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.cluster-state.outputs.ghost_cluster
}

data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.cluster-state.outputs.ghost_cluster
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

resource "helm_release" "ghost-chart" {
  name       = "ghost-chart"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "ghost"

  set {
    name  = "persistence.enabled"
    value = "false"
  }

  set {
    name  = "mysql.primary.persistence.enabled"
    value = "false"
  }

  set {
    name  = "ingress.enabled"
    value = "true"
  }

  set {
    name  = "podAnnotations"
    value = "service.beta.kubernetes.io/aws-load-balancer-type: alb"
  }

  set {
    name  = "podAnnotations"
    value = "service.beta.kubernetes.io/aws-load-balancer-backend-protocol: tcp"
  }
}

resource "helm_release" "lb" {
  name       = "alb-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "awsRegion"
    value = "us-west-2"
  }

  set {
    name  = "rbac.create"
    value = "true"
  }

  set {
    name  = "region"
    value = "us-west-2"
  }

  set {
    name  = "singleNamespace"
    value = "true"
  }

  set {
    name  = "watchNamespace"
    value = "default"
  }

}
