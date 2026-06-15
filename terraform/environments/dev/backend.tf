terraform {
  backend "s3" {
    bucket = "truetally-terraform-state"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"

    encrypt = true
  }
}
