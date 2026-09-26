terraform {
  backend "s3" {
    bucket         = "my-terraform-state" 
    region         = "ap-south-2" 
    key            = "backend/test/terraform.tfstate"
    dynamodb_table = "terraform-lock-table" 
    encrypt        = true                    
  }
}
