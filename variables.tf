variable "company_name" {
  description = "Company name"
  default     = "nt"
}

variable "project_name" {
  description = "Project name"
  default     = "awse"
}

variable "access_key" {
  description = "AWS access key"
}

variable "secret_key" {
  description = "AWS secret access key"
}

variable "region" {
  description = "AWS region to host your network"
  default     = "eu-west-1"
}

variable "trusted_networks" {
  description = "CIDR block of trusted network (such as office network). Traffic from here will bypass most of the security groups."
  default     = ["83.145.221.1/32"]
}

variable "cidr_subnet_public" {
  description = "Subnet address for public network"
  default     = [
    "172.100.1.0/24",
    "172.100.2.0/24"
  ]
}

variable "env" {
  description = "Name of the environment"
  default     = "dev"
}

variable "cidr_vpc" {
  description = "Subnet address for VPC"
  default     = "172.100.0.0/16"
}

variable "ecs-instance-max-size" {
  description = "Max number of ECS instances"
  default     = 4
}

variable "ecs-instance-min-size" {
  description = "Min number of ECS instances"
  default     = 1
}

variable "ecs-instance-desired-size" {
  description = "Desired number of ECS instances"
  default     = 2
}

variable "ecs-instance-image-id" {
  description = "Image ID for ECS instance"
  default     = "ami-0b8e62ddc09226d0a"
}

variable "ecs-instance-type" {
  description = "Type of ECS instance"
  default     = "t2.medium"
}

variable "github_oauth_token" {
  description = "Github authentication token"
}

variable "github_webhook_secret" {
  description = "Github webhook secret"
}

variable "github_organization" {
  description = "Github organization"
}
