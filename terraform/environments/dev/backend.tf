terraform {
  backend "s3" {
    bucket         = "truetally-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "truetally-terraform-locks"
    encrypt        = true
  }
}
