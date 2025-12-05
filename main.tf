terraform {
  backend "s3" {
    bucket  = "innovatech-terraform-state"
    key     = "terraform.tfstate"
    region  = "eu-central-1"
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    mysql = {
      source  = "terraform-providers/mysql"  # TERUG NAAR DEZE
      version = "1.9.0"                      # SPECIFIEKE VERSIE
    }
    null = {
      source = "hashicorp/null"
      version = "~> 3.1"
    }
  }

  required_version = ">= 1.5.0"
}

provider "aws" {
  region = "eu-central-1"
}

provider "docker" {}

provider "null" {}

resource "random_id" "suffix" {
  byte_length = 2
}

resource "aws_ecr_repository" "website" {
  name = "my-website"
}