terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
  }

  # Remote state in S3 — create bucket manually first, then uncomment
  # backend "s3" {
  #   bucket         = "physioconnect-terraform-state"
  #   key            = "production/terraform.tfstate"
  #   region         = "ap-south-1"
  #   encrypt        = true
  #   dynamodb_table = "physioconnect-terraform-locks"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# us-east-1 provider for CloudFront ACM certs
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

locals {
  name_prefix = "${var.project}-${var.environment}"
}
