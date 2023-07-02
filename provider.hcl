locals {
  # Automatically load account-level variables
  relative_deployment_path   = path_relative_to_include()
  deployment_path_components = compact(split("/", local.relative_deployment_path))


  env        = local.deployment_path_components[0]
  aws_region = local.deployment_path_components[1]
}
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket         = "delos-terraform-state-${local.env}-test"
    region         = "us-east-1"
    encrypt        = true
    key            = "${local.relative_deployment_path}/terraform.tfstate"
    dynamodb_table = "delos-terraform-state-locks-${local.aws_region}"
  }
}

# Generate an AWS provider block
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  version = "4.67.0"
  region = "${local.aws_region}"
}
EOF
}

