# Pins Terraform + the AWS provider so everyone (and future-you) gets the same
# behaviour. The provider reads credentials from your `aws configure` setup.
terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}
