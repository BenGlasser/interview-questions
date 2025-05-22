terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket-name"
    key            = "terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
} 