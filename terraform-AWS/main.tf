terraform {
  backend "s3" {
    bucket         = "tfstate-354923279633"
    key            = "text2site/terraform.tfstate"      # Unique key for the app
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}


