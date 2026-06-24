terraform {
  backend "s3" {
    bucket = "truetally-terraform-state"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"

    encrypt = true
  }
}
