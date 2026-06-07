terraform{
  required_providers{
    aws={source="hashicorp/aws",version="~>5.0"}
    random={source="hashicorp/random",version="~>3.5"}
  }
  backend"local"{
    path="terraform.tfstate"
  }
}

provider"aws"{
  region=var.aws_region
  default_tags{
    tags={
      Project    =var.project_name
      Environment=terraform.workspace
      ManagedBy  ="terraform"
    }
  }
}

variable "aws_region"{
  type=string
  default="us-east-1"
}