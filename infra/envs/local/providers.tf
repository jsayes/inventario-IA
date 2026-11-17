# ============================================================================
#  Entorno local contra LocalStack. No requiere cuenta de AWS ni costo.
#  Las credenciales "test" son las que acepta LocalStack; no son secretos.
# ============================================================================
terraform {
  required_version = ">= 1.6, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.6"
    }
  }
}

provider "aws" {
  region                      = var.region
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    apigateway     = var.endpoint_localstack
    cloudwatch     = var.endpoint_localstack
    cloudwatchlogs = var.endpoint_localstack
    dynamodb       = var.endpoint_localstack
    iam            = var.endpoint_localstack
    lambda         = var.endpoint_localstack
    s3             = var.endpoint_localstack
    secretsmanager = var.endpoint_localstack
    sns            = var.endpoint_localstack
    sqs            = var.endpoint_localstack
    ssm            = var.endpoint_localstack
    sts            = var.endpoint_localstack
  }

  default_tags {
    tags = local.tags
  }
}
