terraform {
  backend "s3" {
    bucket         = "terraform-state-354923279633"
    key            = "app/terraform.tfstate"      # Unique key for the app
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}


