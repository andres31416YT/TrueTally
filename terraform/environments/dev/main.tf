module "networking" {
  source = "../../modules/networking"
}

module "security" {
  source = "../../modules/security"
}

module "database" {
  source = "../../modules/database"
}

module "compute" {
  source = "../../modules/compute"
}

module "frontend" {
  source = "../../modules/frontend"
}