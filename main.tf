terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket = "bucket-core3"
    key    = "terraform/state.tfstate"
    region = "eu-west-1"
  }
}

provider "aws" {
  region = "eu-west-1"
}
