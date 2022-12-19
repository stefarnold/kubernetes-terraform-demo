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

## If you want multi region:
# create extra providers with aliases. 
# provider "aws" {
#   alias  = "failover"
#   region = "us-east-1"
# }
