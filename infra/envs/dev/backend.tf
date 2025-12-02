
terraform {
  backend "s3" {
    bucket               = "tfstate-manojbarik-fargate"
    region               = "ap-southeast-2"
    dynamodb_table       = "tf-locks-fargate"
    encrypt              = true
    key                  = "global/terraform.tfstate"
    workspace_key_prefix = "fargate-microservices"
  }
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
