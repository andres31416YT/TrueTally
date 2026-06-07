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
  environment="prod"
  db_password="prod-super-seguro"
}

module"networking"{
  source="../../modules/networking"
  vpc_cidr="10.1.0.0/16"
  azs=["us-east-1a","us-east-1b"]
}

module"database"{
  source="../../modules/database"
  project_name="truetally"
  environment="prod"
  db_username="truetally"
  db_password="prod-super-seguro"
  vpc_cidr="10.1.0.0/16"
  azs=["us-east-1a","us-east-1b"]
  depends_on=[module.security]
}

module"compute"{
  source="../../modules/compute"
  project_name="truetally"
  environment="prod"
  lambda_node_url_az1="http://truetally-prod-blockchain-alb-1.elb.amazonaws.com:9944"
  lambda_node_url_az2="http://truetally-prod-blockchain-alb-2.elb.amazonaws.com:9944"
  vpc_cidr="10.1.0.0/16"
  azs=["us-east-1a","us-east-1b"]
}

module"frontend"{
  source="../../modules/frontend"
  project_name="truetally"
  environment="prod"
  domain_name="app.truetally.com"
  ssl_certificate_arn="arn:aws:acm:us-east-1:1234567890:certificate/xxxx"
  route53_zone_id="Z1234567890ABC"
}