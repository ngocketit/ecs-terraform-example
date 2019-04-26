provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
  version = "~> 2.0"
}

provider "null" {
  version = "1.0.0"
}

provider "template" {
  version = "1.0.0"
}

provider "github" {
  version = "1.3.0"
  token        = "${var.github_oauth_token}"
  organization = "${var.github_organization}"
}
