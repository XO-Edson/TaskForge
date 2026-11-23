terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

# Read the existing EKS cluster.
data "aws_eks_cluster" "taskforge" {
  name = "taskforge"
}

# Configure Helm to connect to that cluster.
provider "helm" {
  kubernetes {
    host = data.aws_eks_cluster.taskforge.endpoint

    cluster_ca_certificate = base64decode(
      data.aws_eks_cluster.taskforge.certificate_authority[0].data
    )

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"

      args = [
        "eks",
        "get-token",
        "--cluster-name",
        "taskforge",
        "--region",
        "eu-central-1"
      ]
    }
  }
}

# Manage the AWS Load Balancer Controller Helm release.
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.14.0"
  namespace  = "kube-system"

  values = [
    yamlencode({
      clusterName = "taskforge"
      region      = "eu-central-1"
      vpcId       = data.aws_eks_cluster.taskforge.vpc_config[0].vpc_id

      serviceAccount = {
        create = true
        name   = "aws-load-balancer-controller"
      }
    })
  ]
}
