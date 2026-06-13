locals {
  project_name        = var.project_name
  env                 = var.environment
  region              = var.aws_region
  vpc_cidr            = var.vpc_cidr
  azs                 = var.azs
  db_password         = var.db_password
  redis_auth_token    = var.redis_auth_token
  lambda_node_url_az1 = var.lambda_node_url_az1
  lambda_node_url_az2 = var.lambda_node_url_az2
}

module "networking" {
  source       = "../../modules/networking"
  project_name = local.project_name
  env          = local.env
  vpc_cidr     = local.vpc_cidr
  azs          = local.azs
}

module "security" {
  source           = "../../modules/security"
  project_name     = local.project_name
  env              = local.env
  db_password      = local.db_password
  redis_auth_token = local.redis_auth_token
}

module "database" {
  source                   = "../../modules/database"
  project_name             = local.project_name
  env                      = local.env
  db_username              = "truetally"
  db_password              = local.db_password
  redis_auth_token         = local.redis_auth_token
  vpc_id                   = module.networking.vpc_id
  private_subnet_ids       = module.networking.private_subnet_ids
  kms_key_arn              = module.security.kms_key_arn
  lambda_security_group_id = module.networking.lambda_security_group_id
  rds_security_group_id    = module.security.rds_security_group_id
}

module "compute" {
  source                      = "../../modules/compute"
  project_name                = local.project_name
  env                         = local.env
  vpc_cidr                    = local.vpc_cidr
  azs                         = local.azs
  vpc_id                      = module.networking.vpc_id
  public_subnet_ids           = module.networking.public_subnet_ids
  private_subnet_ids          = module.networking.private_subnet_ids
  kms_key_arn                 = module.security.kms_key_arn
  lambda_security_group_id    = module.networking.lambda_security_group_id
  lambda_sg_arn               = module.networking.lambda_sg_arn
  db_credentials_secret_arn   = module.security.db_credentials_secret_arn
  redis_auth_token_secret_arn = module.security.redis_auth_token_secret_arn
  lambda_node_url_az1         = local.lambda_node_url_az1
  lambda_node_url_az2         = local.lambda_node_url_az2
  rds_proxy_endpoint          = module.database.rds_proxy_endpoint
  rds_endpoint                = module.database.rds_endpoint
  redis_endpoint              = module.database.redis_endpoint
  redis_port                  = module.database.redis_port
}
