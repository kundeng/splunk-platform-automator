# Dummy AWS provider configuration for dev environment
# This is needed because the AWS provider is still initialized by the platform module
provider "aws" {
  region                      = "us-west-2"  # Dummy region
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  s3_use_path_style          = true

  # Dummy credentials
  access_key = "mock_access_key"
  secret_key = "mock_secret_key"
}
