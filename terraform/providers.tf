terraform {
  required_version = ">= 1.5"
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
    key    = "infrastructure/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    kms_key_id = "alias/terraform-state-key"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "truetally"
      Environment = terraform.workspace
      ManagedBy   = "terraform"
    }
  }
}

locals {
  azs = ["us-east-1a", "us-east-1b"]
  name_prefix = "${var.project_name}-${terraform.workspace}"
}