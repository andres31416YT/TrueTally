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
}

provider "aws" {
  region = var.aws_region
}

module "networking" {
  source = "../../modules/networking"

  vpc_cidr = var.vpc_cidr
  azs      = var.azs
}

module "security" {
  source = "../../modules/security"
}

module "database" {
  source = "../../modules/database"

  db_username = var.db_username
  db_password = var.db_password
  depends_on   = [module.security]
}

module "compute" {
  source = "../../modules/compute"

  lambda_node_url_az1 = var.lambda_node_url_az1
  lambda_node_url_az2 = var.lambda_node_url_az2
  depends_on           = [module.database, module.networking]
}

module "frontend" {
  source = "../../modules/frontend"

  domain_name        = var.domain_name
  ssl_certificate_arn = var.ssl_certificate_arn
  route53_zone_id    = var.route53_zone_id
}