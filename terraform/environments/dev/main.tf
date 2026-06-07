terraform{
  required_providers{
    aws={source="hashicorp/aws",version="~>5.0"}
    random={source="hashicorp/random",version="~>3.5"}
  }
}

provider"aws"{
  region="us-east-1"
}

module"security"{
  source="../../modules/security"
  project_name="truetally"
  environment="dev"
  db_password="dev-seguro"
}

module"networking"{
  source="../../modules/networking"
  vpc_cidr="10.0.0.0/16"
  azs=["us-east-1a","us-east-1b"]
}

module"database"{
  source="../../modules/database"
  project_name="truetally"
  environment="dev"
  db_username="truetally"
  db_password="dev-seguro"
  vpc_cidr="10.0.0.0/16"
  azs=["us-east-1a","us-east-1b"]
  depends_on=[module.security]
}

module"compute"{
  source="../../modules/compute"
  project_name="truetally"
  environment="dev"
  lambda_node_url_az1="http://localhost:9944"
  lambda_node_url_az2="http://localhost:9944"
  vpc_cidr="10.0.0.0/16"
  azs=["us-east-1a","us-east-1b"]
}

module"frontend"{
  source="../../modules/frontend"
  project_name="truetally"
  environment="dev"
  domain_name=""
  ssl_certificate_arn=""
  route53_zone_id=""
}