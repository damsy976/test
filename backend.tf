terraform {
  backend "s3" {
    bucket         = "damsy1-terraform-state" 
    region         = "ap-south-2" 
    key            = "backend1/test1/terraform.tfstate"
    dynamodb_table = "terraform-lock-table" 
    encrypt        = true                    
  }
}
