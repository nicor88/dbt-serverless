provider "aws" {
  region = "${var.aws_region}"
}

terraform {
  backend "s3" {
    bucket         = "nicor88-eu-west-1-terraform"
    key            = "dbt-serverless/terraform.tfstate"
    region         = "eu-west-1"
  }
}
