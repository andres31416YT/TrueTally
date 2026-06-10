locals {
  project_name = var.project_name
  env          = var.environment
  region       = var.aws_region
  vpc_cidr     = var.vpc_cidr
  azs          = var.azs
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
  backend "s3" {
    bucket = "truetally-terraform-state"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = local.region
}

# Prueba CI/CD Dev (ADRIEL): cambio seguro que no altera recursos