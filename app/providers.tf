terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }

    null = {
      source = "hashicorp/null"
    }

    helm = {
      source = "hashicorp/helm"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}