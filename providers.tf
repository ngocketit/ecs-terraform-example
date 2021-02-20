terraform {
  required_version = ">= 0.14"

  required_providers {
    aws = {
      version = ">= 3.0"
    }
  }
}

provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
}

provider "github" {
  token        = var.github_oauth_token
  organization = var.github_organization
}
