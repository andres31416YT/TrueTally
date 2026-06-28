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
  account_id          = var.aws_account_id
}

module "networking" {
  source       = "../../modules/networking"
  project_name = local.project_name
  env          = local.env
  vpc_cidr     = local.vpc_cidr
  azs          = local.azs
  aws_region   = local.region
  kms_key_arn  = module.security.kms_key_arn
}

module "security" {
  source           = "../../modules/security"
  project_name     = local.project_name
  env              = local.env
  db_password      = local.db_password
  redis_auth_token = local.redis_auth_token
}

module "database" {
  source                      = "../../modules/database"
  project_name                = local.project_name
  env                         = local.env
  db_username                 = "truetally"
  db_password                 = local.db_password
  redis_auth_token            = local.redis_auth_token
  vpc_id                      = module.networking.vpc_id
  private_subnet_ids          = concat(module.networking.compute_subnet_ids, module.networking.database_subnet_ids)
  kms_key_arn                 = module.security.kms_key_arn
  lambda_security_group_id    = module.networking.lambda_security_group_id
  database_sg_id              = module.networking.database_sg_id
  db_credentials_secret_arn   = module.security.db_credentials_secret_arn
  redis_auth_token_secret_arn = module.security.redis_auth_token_secret_arn
  skip_final_snapshot         = true
}

module "messaging" {
  source       = "../../modules/messaging"
  project_name = local.project_name
  env          = local.env
  vpc_id       = module.networking.vpc_id
}

module "compute" {
  source                      = "../../modules/compute"
  project_name                = local.project_name
  env                         = local.env
  vpc_id                      = module.networking.vpc_id
  public_subnet_ids           = module.networking.public_subnet_ids
  private_subnet_ids          = module.networking.private_subnet_ids
  blockchain_subnet_ids       = module.networking.blockchain_subnet_ids
  azs                         = local.azs
  kms_key_arn                 = module.security.kms_key_arn
  lambda_security_group_id    = module.networking.lambda_security_group_id
  blockchain_security_group_id = module.networking.blockchain_sg_id
  lambda_sg_arn               = module.networking.lambda_sg_arn
  db_credentials_secret_arn   = module.security.db_credentials_secret_arn
  redis_auth_token_secret_arn = module.security.redis_auth_token_secret_arn
  vote_queue_arn              = module.messaging.vote_queue_arn
  vote_queue_url              = module.messaging.vote_queue_url
  lambda_node_url_az1         = local.lambda_node_url_az1
  lambda_node_url_az2         = local.lambda_node_url_az2
  ecr_repository_url          = module.security.ecr_repository_url
  lambda_zip_path             = var.lambda_zip_path
  dlq_arn                     = module.messaging.dlq_arn
}

module "frontend" {
  source                 = "../../modules/frontend"
  providers              = { aws.us_east_1 = aws.us_east_1 }
  project_name           = local.project_name
  env                    = local.env
  aws_region             = local.region
  domain_name            = var.domain_name
  ssl_certificate_arn    = var.ssl_certificate_arn
  create_acm_certificate = var.create_acm_certificate
  route53_zone_id        = var.route53_zone_id
  enabled                = true
  kms_key_arn            = module.security.kms_key_arn
  bucket_suffix          = local.account_id
}

module "monitoring" {
  source       = "../../modules/monitoring"
  project_name = local.project_name
  env          = local.env
  kms_key_arn  = module.security.kms_key_arn
}