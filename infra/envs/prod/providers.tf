# ============================================================================
#  Entorno de producción (AWS real). En esta prueba NO se aplica: solo se
#  valida y se planifica. No necesitas cuenta de AWS para `terraform validate`.
# ============================================================================
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
    archive = {
      source = "hashicorp/archive"
    }
  }
}

provider "aws" {
  region = var.region
}
