terraform {
  backend "s3" {
    bucket         = "launch-terraform-state" # TODO: Replace with your actual bucket name
    key            = "launch/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "launch-terraform-lock"  # TODO: Replace with your actual lock table (optional but recommended)
  }
}
