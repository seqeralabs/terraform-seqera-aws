terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.23.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.11.0"
    }
  }
}
